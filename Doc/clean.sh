#!/bin/sh
rubber --pdf --clean LFCamExplore
rm *.log > /dev/null 2>&1
rm *.aux *.out *.blg *.bbl *.ist *.gls *.glg > /dev/null 2>&1
