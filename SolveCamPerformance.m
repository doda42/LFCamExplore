% SolveCamPerformance.m: Estimate camera performance for a given CamInfo
% 
% CamInfo describes a lenslet-based plenoptic camera in terms of optical and mechanical
% configuration. It must include the lens positions, e.g. as provided by SolveLensPositions. Based
% on this description, this function estimates key performance metrics.
% 
% Warning: this function is experimental and currently yields misleading results for some camera
% configurations.  More work todo!
% 
% This is part of LFCamExplore, a tool for building intuition in the design space of plenoptic
% cameras.
% 
% Please see LFCamExploreGUI.m and LFCamExplore.pdf for further information.

% Copyright (c) 2017 Donald G. Dansereau

function CamPerformance = SolveCamPerformance( CamInfo )

%---Check specs---
CamPerformance.TheoreticFOV_deg = 2*atan( CamInfo.SensorSize_m/2 /(CamInfo.MainLensDist_m - CamInfo.LensletDist_m) ) * 180/pi;
CamPerformance.FOVFootPrint_at_FocalDepth_mm =  1e3*2*CamInfo.FocalDepth_m*tan(0.5*CamPerformance.TheoreticFOV_deg*pi/180);

if( isfield(CamInfo, 'Plen2FocDist_m') && ~isempty(CamInfo.Plen2FocDist_m) )
    PixelHeight_Plen2Img = CamInfo.PixelSize_m / CamInfo.LensletDist_m * abs(CamInfo.Plen2FocDist_m-CamInfo.LensletDist_m);
    CamPerformance.PixelFootprint_at_FocalDepth_mm = 1e3*PixelHeight_Plen2Img/(CamInfo.MainLensDist_m-CamInfo.Plen2FocDist_m) * (CamInfo.FocalDepth_m-CamInfo.MainLensDist_m);
else
    CamPerformance.PixelFootprint_at_FocalDepth_mm = CamPerformance.FOVFootPrint_at_FocalDepth_mm / CamInfo.NLenslets;
end

CamPerformance.MaxLensletAlignError_m = CamInfo.LensletDist_m / CamInfo.LensletDiam_m * CamInfo.PixelSize_m;
CamPerformance.MaxLensletAngularAlignErrorDeg = atan(CamPerformance.MaxLensletAlignError_m / (CamInfo.SensorSize_m/2))*180/pi;
CamPerformance.MaxLensletAngularAlignErrorArcSec = CamPerformance.MaxLensletAngularAlignErrorDeg * 3600;

CamPerformance.EffectiveFNumber  = (CamInfo.MainLensDist_m - CamInfo.LensletDist_m) / CamInfo.MainLensDiam_m;
CamPerformance.LensletFNumber = CamInfo.LensletFocal_m./CamInfo.LensletDiam_m;
CamPerformance.MainLensFNumber = CamInfo.MainLensFocal_m/ CamInfo.MainLensDiam_m;

if( isfield(CamInfo, 'Plen2FocDist_m') && ~isempty(CamInfo.Plen2FocDist_m) )
    x2 = CamInfo.MainLensDiam_m/2 .* abs(CamInfo.Plen2FocDist_m - CamInfo.LensletDist_m) ./ (CamInfo.MainLensDist_m - CamInfo.Plen2FocDist_m);
    CamPerformance.NumAngularSamples = 2 * x2 ./ CamInfo.LensletDiam_m;
else
    CamPerformance.NumAngularSamples = CamInfo.PixelsPerLenslet;
end

CamPerformance.NumSpatialSamples = CamInfo.NPixels / CamPerformance.NumAngularSamples;

%---Depth of field approximation---
PixWidth_s = CamInfo.MainLensDiam_m / CamPerformance.NumAngularSamples;
PixHeight_u = CamPerformance.PixelFootprint_at_FocalDepth_mm / 1e3;
CamPerformance.NaiveNearFocalLimit_m = CamInfo.FocalDepth_m / (1+PixHeight_u/PixWidth_s);
CamPerformance.NaiveFarFocalLimit_m = CamInfo.FocalDepth_m / max(0,(1-PixHeight_u/PixWidth_s));
% %---depth of field check for conventional camera---
% H = CamInfo.MainLensFocal_m^2 / (CamPerformance.MainLensFNumber * CamInfo.PixelSize_m)
% Dn = H * CamInfo.FocalDepth_m / (H + CamInfo.FocalDepth_m)
% Df = H * CamInfo.FocalDepth_m / (H - CamInfo.FocalDepth_m)