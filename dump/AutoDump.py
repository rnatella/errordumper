def printVariables():

	frame = gdb.selected_frame()
	block = frame.block()
	variables = {}

	while block:
		for symbol in block:
			if (symbol.is_argument or symbol.is_variable):


				if 'FILE' in str(symbol.type):
					print "SKIPPING: "+symbol.name+" ("+str(symbol.type)+")\n"
					continue

				variables[symbol.name] = symbol

		block = block.superblock


	for var_name in sorted(variables.iterkeys()):

		try:

			sym = variables[var_name]


			gdb.write('VAR: ' + '[' + str(sym.type.strip_typedefs()) + '] ' + str(sym) + ' = ')
			gdb.execute('print ' + var_name)
			gdb.write('\n')


			if ((sym.type.code == gdb.TYPE_CODE_PTR) or ((sym.type.code == gdb.TYPE_CODE_TYPEDEF) and (sym.type.strip_typedefs().code == gdb.TYPE_CODE_PTR))):

				dyn_type_str = '('+str(sym.value(gdb.selected_frame()).dynamic_type)+')'

				gdb.write('VAR: ' + '[' + str(sym.type.strip_typedefs().target()) + '] *' + str(sym) + ' = ')
				gdb.execute('print *' + dyn_type_str + var_name)
				gdb.write('\n')


		except RuntimeError, e:
			gdb.write('<INVALID>\n\n')


