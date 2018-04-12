import gdb
import re
import os
import os.path
import sys
import binascii
from subprocess import check_output
from intervaltree import Interval, IntervalTree


address_dict = {}
heap_areas = IntervalTree()
alloc_sites_count = {}

stack_begin_address = 0
stack_end_address = 0

data_begin_address = 0
data_end_address = 0

rodata_begin_address = 0
rodata_end_address = 0

bss_begin_address = 0
bss_end_address = 0

text_begin_address = 0
text_end_address = 0


scriptpath = str(os.environ['SCRIPTDIR'])+'/dump'
MAX_SIZE_PP = int(os.environ['BINARYDUMP'])







import time


def update_mtrace():

	if not("MALLOC_TRACE" in os.environ):
		raise ValueError('Env. variables for MTRACE not defined')


	if not(os.path.isfile(str(os.environ['MALLOC_TRACE']))) or (os.stat(str(os.environ['MALLOC_TRACE'])).st_size == 0):
		return None



	for line in open(str(os.environ['MALLOC_TRACE'])).readlines():

		cols = line.split()

		if not(cols[0] == "@"):
			continue


		if (cols[2] == "+") or (cols[2] == ">"):

			address_area = long(cols[3], 16)
			size_byte = int(cols[4], 16)
			alloc_site = cols[1]


			try:
				alloc_sites_count[alloc_site] = alloc_sites_count[alloc_site]+1

			except KeyError:

				alloc_sites_count[alloc_site] = 1


			heap_areas[address_area:address_area+size_byte+1] = (size_byte, alloc_site, alloc_sites_count[alloc_site])

			# NOTE: the "+1" includes pointers to the first-after-last location of the areas


		elif (cols[2] == "-") or (cols[2] == "<"):

			address_area = long(cols[3], 16)

			heap_areas.remove_overlap(address_area)



def heap_dump(dump_iter):

	global MAX_SIZE_PP

	if MAX_SIZE_PP == 0:
		return


	for area in heap_areas:

		address_area = area.begin
		size_byte = area.data[0]
		alloc_site = area.data[1]
		alloc_count = area.data[2]


		if size_byte <= MAX_SIZE_PP:
			continue


		alloc_id = get_alloc_id(alloc_site, alloc_count)


		dumpfilepath = str(dump_iter) + "-" + hex(address_area) + "-" + str(size_byte) + "-" + str(alloc_id) + ".dump"

		dumpfile = open(dumpfilepath, 'wb')

		dumpfile.write( bytearray(gdb.selected_inferior().read_memory(address_area, size_byte)) )

		dumpfile.close()



def get_alloc_id(alloc_site, alloc_count):

	(call1, call2) = alloc_site.split("/")

	return (long(call1, 16) ^ long(call2, 16)) + alloc_count


 
def lookup_function (val):
	"Look-up and return a pretty-printer that can print val."

	type = val.type
	 
	if type.code == gdb.TYPE_CODE_REF:
		type = type.target ()
	 
	type = type.unqualified ().strip_typedefs ()


	if type.code == gdb.TYPE_CODE_STRUCT:
		return GenericPrinter(val)

	if type.code == gdb.TYPE_CODE_PTR:
		return PointerPrinter(val)

	if type.code == gdb.TYPE_CODE_FLT:
		return FloatPrinter(val)

	if type.code == gdb.TYPE_CODE_COMPLEX:
		return ComplexFloatPrinter(val)

	return None



class FloatPrinter:

	def __init__(self, val):
		self.val = val

	def to_string(self):
		return float(self.val).hex()


class ComplexFloatPrinter:

	def __init__(self, val):
		self.val = val

	def to_string(self):

		real = self.val.cast( self.val.type.target() )

		img = gdb.Value(real.address + 1).cast( self.val.type.target().pointer() ).dereference()

		return float(real).hex() + " + " + float(img).hex() + " * I"


class PointerPrinter:

	def __init__(self, val):
		self.val = val

	def to_string(self):

		if (self.val is None):
			return ''

		address_val = long(self.val);

		pointer_str = hex(((1 << 64) - 1) & address_val).rstrip('L')


		address_area = -1L
		size_byte = -1
		size = -1

		address_query = heap_areas[address_val]


		if address_query:

			interval = sorted(address_query)[0]

			address_area = interval.begin
			size_byte = interval.data[0]
			alloc_site = interval.data[1]
			alloc_count = interval.data[2]


		if (address_area == -1L):

			if (address_val <= stack_begin_address) and (address_val >= stack_end_address):

				pointer_str = pointer_str + ' <STACK(-'+str(stack_begin_address-address_val)+')>' 

			elif (address_val <= data_end_address) and (address_val >= data_begin_address):

				pointer_str = pointer_str + ' <DATA(+'+str(address_val-data_begin_address)+')>' 

			elif (address_val <= rodata_end_address) and (address_val >= rodata_begin_address):

				pointer_str = pointer_str + ' <RODATA(+'+str(address_val-rodata_begin_address)+')>' 

			elif (address_val <= bss_end_address) and (address_val >= bss_begin_address):

				pointer_str = pointer_str + ' <BSS(+'+str(address_val-bss_begin_address)+')>' 

			elif (address_val <= text_end_address) and (address_val >= text_begin_address):

				pointer_str = pointer_str + ' <TEXT(+'+str(address_val-text_begin_address)+')>' 

			else:
				pointer_str = pointer_str + ' <ANY>'

		else:

			alloc_id = get_alloc_id(alloc_site, alloc_count)

			pointer_offset = address_val - address_area

			pointer_str = pointer_str + ' <HEAP('+str(alloc_id)+','+str(size_byte)+',+'+str(pointer_offset)+')>'


		return pointer_str




class GenericPrinter:

	def __init__(self, val):

		if val.address is not None:
			address_dict[long(str(val.address).split()[0],16)] = 1
			self.val = val

		else:
			self.val = None

	def to_string(self):
		return 'Struct' if not(self.val is None) else 'None'


	def children(self):

		if (self.val is None):
			return

		for k, v in process_kids(self.val, self.val):

			for k2, v2 in printer(k, v):

				yield k2, v2



def process_kids(state, PF):

	if PF.type.code == gdb.TYPE_CODE_REF:
		PF = PF.referenced_value()


	for field in PF.type.fields():

		if field.artificial or field.type.code == gdb.TYPE_CODE_FUNC or \
		field.type.code == gdb.TYPE_CODE_VOID or field.type.code == gdb.TYPE_CODE_METHOD or \
		field.type.code == gdb.TYPE_CODE_METHODPTR or field.type == None: 
			continue


		key = field.name
		if key is None: 
			continue

		try: state[key]
		except RuntimeError: 
			continue

		val = PF[key]


		if field.is_base_class and len(field.type.fields()) != 0:
			for k, v in process_kids(state, field):
				yield key + " :: " + k, v
		else:
			yield key, val



def printer(key, val, recursive=False):

	val_type=val.type.strip_typedefs()


	if val_type.code == gdb.TYPE_CODE_PTR or val_type.code == gdb.TYPE_CODE_MEMBERPTR:


		if not val: 
			return

		elif 'char' in str(val.type) or 'Char' in str(val.type):
			yield '[' + str(val_type) + '] ' + key, val

			val_string = ""

			try:
				val_string = val.string('ascii')
				yield '[' + str(val_type.target()) + '[]] *' + key, '"'+val_string+'"'
			except:

				address_query = heap_areas[long(val)]

				if address_query:

					interval = sorted(address_query)[0]

					address_area = interval.begin
					size_byte = interval.data[0]

					if (address_area != -1L):

						try:
							val_string = binascii.hexlify( bytearray(gdb.selected_inferior().read_memory(address_area, size_byte)) )
							yield '[' + str(val_type.target()) + '[]] *' + key, '"'+val_string+'"'

						except:
							pass



		else:
			try:

				if(val.dereference() != val.dereference()):
					pass


				if val_type.target().code == gdb.TYPE_CODE_VOID:

					yield '[' + str(val_type) + '] ' + key, val

				else:


						if (val.dynamic_type != val.type):
							val = val.dynamic_cast(val.dynamic_type)
							val_type=val.type.strip_typedefs()




						address_val = long( str(val).split()[0], 16 )	# Remove symbol name from function pointer strings


						address_area = -1L
						size_byte = -1
						size = -1


						address_query = heap_areas[address_val]


						if address_query:

							interval = sorted(address_query)[0]

							address_area = interval.begin
							size_byte = interval.data[0]
							alloc_site = interval.data[1]
							alloc_count = interval.data[2]

							size = size_byte / val_type.target().sizeof	# convert size-in-bytes to number-of-pointed-elements





						if (address_area == -1L):

							if (address_val <= stack_begin_address) and (address_val >= stack_end_address):

								yield '[' + str(val_type.target()) + '] *' + key, hex(address_val)+' <STACK(-'+str(stack_begin_address-address_val)+')>'

							elif (address_val <= data_end_address) and (address_val >= data_begin_address):

								yield '[' + str(val_type.target()) + '] *' + key, hex(address_val)+' <DATA(+'+str(address_val-data_begin_address)+')>'

							elif (address_val <= rodata_end_address) and (address_val >= rodata_begin_address):

								yield '[' + str(val_type.target()) + '] *' + key, hex(address_val)+' <RODATA(+'+str(address_val-rodata_begin_address)+')>'

							elif (address_val <= bss_end_address) and (address_val >= bss_begin_address):

								yield '[' + str(val_type.target()) + '] *' + key, hex(address_val)+' <BSS(+'+str(address_val-bss_begin_address)+')>'

							elif (address_val <= text_end_address) and (address_val >= text_begin_address):

								yield '[' + str(val_type.target()) + '] *' + key, hex(address_val)+' <TEXT(+'+str(address_val-text_begin_address)+')>'

							else:
								yield '[' + str(val_type.target()) + '] *' + key, hex(address_val)+' <ANY>'


						else:




							if recursive == False:

								yield '[' + str(val_type) + '] ' + key, str(val)



							alloc_id = get_alloc_id(alloc_site, alloc_count)

							pointer_offset = address_val - address_area


							if not(address_area in address_dict):

								address_dict[address_area] = 1


								if size > 1:

									global MAX_SIZE_PP

									if (MAX_SIZE_PP == 0) or (size_byte <= MAX_SIZE_PP):


										array_expr = '*('+str(val.type)+')'+hex(address_area)+'@'+str(size)
										array_parsed = gdb.parse_and_eval( array_expr )
										yield '[' + str(val_type.target()) + '['+str(size)+']] *' + key, array_parsed



										if val_type.target().code == gdb.TYPE_CODE_PTR:

											start = (address_area-address_val) / val_type.target().sizeof
											for i in range(start, start+size):
												for k,v in printer(key+"["+str(i-start)+"]", (val + i).dereference(), True):
													yield k,v


									else:
										yield '[' + str(val_type.target()) + '['+str(size)+']] *' + key, '<BINARYDUMP> <HEAP('+str(alloc_id)+','+str(size_byte)+',+'+str(pointer_offset)+')>'


								else:

									for k,v in printer( '*'+key, val.dereference(), True):
										yield k,v


							else:
								# The heap area has already been dereferenced and dumped

								if size > 1:

									yield '[' + str(val_type.target()) + '['+str(size)+']] *' + key, '<PRINTED> <HEAP('+str(alloc_id)+','+str(size_byte)+',+'+str(pointer_offset)+'>'

								else:
									yield '[' + str(val_type.target()) + '] *' + key, '<PRINTED> <HEAP('+str(alloc_id)+','+str(size_byte)+',+'+str(pointer_offset)+'>'




			except RuntimeError:

				yield '[' + str(val_type.target()) + '] *' + key, str(val)+' <INVALID>'



	elif 'std::vector' in str(val_type):

		try:
			size = int(val['_M_impl']['_M_finish'] - val['_M_impl']['_M_start'])

			if (size > 0) and (size < 100000):

				yield '[' + str(val.type.strip_typedefs()) + '] ' + key, val


				if val.type.template_argument(0).code == gdb.TYPE_CODE_PTR:

					for i in range(0, size):
						for k,v in printer(key+"["+str(i)+"]", (val['_M_impl']['_M_start'] + i).dereference(), True):
							yield k,v
		except:
			pass


	else:
		yield '[' + str(val.type.strip_typedefs()) + '] ' + key, val



gdb.pretty_printers.append(lookup_function)


sys.path.insert(0, scriptpath+'/STL/python')
from libstdcxx.v6.printers import register_libstdcxx_printers
register_libstdcxx_printers (None)

