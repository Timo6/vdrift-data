#!/usr/bin/python

import sys, getopt, codecs

def main(argv):
	inputfile = ''
	outputfile = ''
	try:
		opts, args = getopt.getopt(argv, 'hi:o:', ['ifile=', 'ofile='])
	except getopt.GetoptError:
		print 'po2cfg.py -i <inputfile> -o <outputfile>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'po2cfg.py -i <inputfile> -o <outputfile>'
			sys.exit()
		elif opt in ('-i', '--ifile'):
			inputfile = arg
		elif opt in ('-o', '--ofile'):
			outputfile = arg
	if not inputfile or not outputfile:
		print 'po2cfg.py -i <inputfile> -o <outputfile>'
		sys.exit(2)
		
	input = codecs.open(inputfile, 'r', 'utf-8')
	strings = []
	i = ''
	s = ''
	id = 'n'
	line = input.readline()
	while line != '':
		if line.startswith('msgid'):
			i = line.split('"', 1)[1].rsplit('"', 1)[0]
			id = 'i'
		elif len(i) and line.startswith('msgstr'):
			s = line.split('"', 1)[1].rsplit('"', 1)[0]
			id = 's'
		elif line.startswith('"'):
			line = line.split('"', 1)[1].rsplit('"', 1)[0]
			if (id == 'i'):
				i = i + line
			elif (id == 's'):
				s = s + line
			else:
				id = 'n'
		else:
			if len(i):
				i = i.replace('\\"', '"')
				if len(s):
					s = s.replace('\\"', '"')
					strings.append(i + ' = ' + s + '\n')
				else:
					strings.append('#' + i + ' = \n')
			i = ''
			s = ''
			id = 'n'
		line = input.readline()
	input.close()
    
	output = codecs.open(outputfile, 'w', 'utf-8')
	for string in strings:
		output.write(string)
	output.close()

if __name__ == '__main__':
	main(sys.argv[1:])
