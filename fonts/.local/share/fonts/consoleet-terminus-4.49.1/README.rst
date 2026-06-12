This is the Terminus bitmap font set, converted to OpenType/OTF.
Both original (jagged-edge) and smoothed variants are provided —
as far as the vfontas algorithm is able to generate it.

* No bold variant for Terminus-12

  ter-u12b.bdf and ter-u12n.bdf are the same; as such, there
  is no Bold OTF variant for T-12.

* No smooth variants for thin strokes

  The smoothing algorithm requires a stroke with of at least two
  pixels; as such, Smooth OTF variants exist only for T-28, T-32
  and T-16 Bold thru T-32 Bold.


Example use
===========

::

	xterm -fa 'Consoleet Terminus\-16:size=12:bold'
	xterm -fa 'Consoleet Terminus\-16 Smooth:size=12:bold'
	xterm -fa 'Consoleet Terminus\-18:size=13.5:bold'
	xterm -fa 'Consoleet Terminus\-22:size=16.5:bold'
	xterm -fa 'Consoleet Terminus\-24:size=18:bold'
	xterm -fa 'Consoleet Terminus\-28:size=21'
	xterm -fa 'Consoleet Terminus\-32 Smooth:size=24'

The backslash is a peculiarity of libfontconfig; you will also
see it in the output of fc-list(1).



- Jan Engelhardt <jengelh@inai.de>.
