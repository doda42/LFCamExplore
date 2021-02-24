% SolveLensPositions - Find camera layout for a given CamInfo
% 
% CamInfo prescribes main lens and lenslet focal lengths, the depth at which the camera is focused,
% and the lenslet diameter.  For plenoptic 2.0 cameras it accepts the focal ratio.  It solves for
% the lenslet and main lens position relative to the sensor.  All distances are relative to the
% sensor.
% 
% This is part of LFCamExplore, a tool for building intuition in the design space of plenoptic
% cameras.
% 
% Please see LFCamExploreGUI.m and LFCamExplore.pdf for further information.

% Copyright (c) 2017-2021 Donald G. Dansereau

function [CamInfo, CamValid] = SolveLensPositions( CamInfo )

CamValid = true;

%---
CamInfo.SensorSize_m = CamInfo.PixelSize_m * CamInfo.NPixels;
CamInfo.LensletDiam_m = CamInfo.PixelsPerLenslet*CamInfo.PixelSize_m;
CamInfo.NLenslets = CamInfo.NPixels / CamInfo.PixelsPerLenslet;

if( any(strcmp(CamInfo.CameraModel, {'Plen1','Plen1FocInf'})) ) % lenslets focused @ inf not main lens
    f2 = CamInfo.MainLensFocal_m;
    P2 = CamInfo.FocalDepth_m;
    f1 = CamInfo.LensletFocal_m;
    L1 = f1;
    x1 = CamInfo.LensletDiam_m;

	L2v(1) = L1/2 + P2/2 - ((L1 - P2)*(L1 - P2 + 4*f2))^(1/2)/2;
	L2v(2) = L1/2 + P2/2 + ((L1 - P2)*(L1 - P2 + 4*f2))^(1/2)/2;
	
    ValidIdx = find(L2v>0 & imag(L2v)==0);
	CamValid = ~isempty(ValidIdx);
	
    L2v = L2v(ValidIdx);
    L2 = min(L2v);

    D2 = x1/f1 .* (L2-L1);
    
    CamInfo.MainLensDiam_m = D2;
    CamInfo.MainLensDist_m = L2;
    CamInfo.LensletDist_m = L1;
    CamInfo.Plen2FocRatio = [];
	CamInfo.Plen2FocDist_m = [];
	
elseif( any(strcmp(CamInfo.CameraModel, {'Plen2','Plen2Front','Plen2Behind'})) )
	f2 = CamInfo.MainLensFocal_m;
	R = CamInfo.Plen2FocRatio;
	P2 = CamInfo.FocalDepth_m;
	f1 = CamInfo.LensletFocal_m;
	x1 = CamInfo.LensletDiam_m;

	L1 = (f1 + R*f1)/R;
	P1 = R*L1 + L1;
	L2v(1) = L1/2 + P2/2 - ((L1 - P2 + L1*R)*(L1 - P2 + 4*f2 + L1*R))^(1/2)/2 + (L1*R)/2;
	L2v(2) = L1/2 + P2/2 + ((L1 - P2 + L1*R)*(L1 - P2 + 4*f2 + L1*R))^(1/2)/2 + (L1*R)/2;
	
	ValidIdx = find(L2v>0 & imag(L2v)==0);
	CamValid = ~isempty(ValidIdx) && L1>0;
	
	L2v = L2v(ValidIdx);
	L2 = min(L2v);
	
	D2 = x1/L1 .* (L2-L1);
	
	CamInfo.MainLensDiam_m = D2;
	CamInfo.MainLensDist_m = L2;
	CamInfo.LensletDist_m = L1;
	CamInfo.Plen2FocDist_m = P1;
	
else
	fprintf('unrecognized camera type');
end




