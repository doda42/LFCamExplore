% SolveIntrinsicMatrix.m: Find the idealized intrinsic matrix for a given camera description.
% 
% CamInfo describes a lenslet-based plenoptic camera in terms of optical and mechanical
% configuration. It must include the lens positions, e.g. as provided by SolveLensPositions. Based
% on this description, this function finds an intrinsic matrix that maps pixel indices to spatial
% rays.
% 
% Based on the camera configuration, pixel centers and marginal rays (corners in the epipolar plane)
% are also computed.
% 
% This function ignores the effect of projection through the main lens, vignetting, diffraction, and
% higher-order effects.  Please see the documentation for more information.
% 
% This is part of LFCamExplore, a tool for building intuition in the design space of plenoptic
% cameras.
% 
% Please see LFCamExploreGUI.m and LFCamExplore.pdf for further information.

% Copyright (c) 2017 Donald G. Dansereau

function [CamIntrins, SUCenters, SUMarginal1, SUMarginal2, DispOptions] = ...
	SolveIntrinsicMatrix( CamInfo, DispOptions )

%---Defaults---
DispOptions = LFDefaultField('DispOptions','STFollowsCamPlane', true);
DispOptions = LFDefaultField('DispOptions','UVFollowsCamPlane', true);
DispOptions = LFDefaultField('DispOptions','AxesFollowSU', true);
DispOptions = LFDefaultField('DispOptions','STPlanePos_m', 0);
DispOptions = LFDefaultField('DispOptions','UVPlanePos_m', 1);

%---Derived---
if( DispOptions.STFollowsCamPlane )
	switch( CamInfo.CameraModel )
		case 'Plen1'
			STPlanePos_m = CamInfo.MainLensDist_m + CamInfo.MainLensFocal_m;
		case 'Plen2'
			STPlanePos_m = CamInfo.MainLensDist_m + 1 / (1/CamInfo.MainLensFocal_m - 1/(CamInfo.MainLensDist_m-CamInfo.LensletDist_m));
	end
else
	STPlanePos_m = DispOptions.STPlanePos_m;
end

if( DispOptions.UVFollowsCamPlane )
	UVPlanePos_m = CamInfo.FocalDepth_m;
else
	UVPlanePos_m = DispOptions.UVPlanePos_m;
end

% camera intrinsics
CamIntrins.STPlanePos_m = STPlanePos_m;
CamIntrins.UVPlanePos_m = UVPlanePos_m;

% For integer pix per lenslet
PixIdx = 0:CamInfo.PixelsPerLenslet-1;
LensletIdx = 0:CamInfo.NLenslets-1;
[LL,PP] = ndgrid(LensletIdx,PixIdx);
LL=LL';
PP=PP';
PP = PP + LL.*CamInfo.PixelsPerLenslet;
P = [PP(:),LL(:), ones(size(LL(:)))]';

% set up marginal rays at edges of pixels
PPm = PP;
LLm = LL;
PPm(end+1,:) = PP(end,:);
LLm(end+1,:) = LL(end,:);
PPm = PPm-0.5;
PPm(end,:) = PPm(end,:)+1;
Pm = [PPm(:),LLm(:), ones(size(LLm(:)))]';

%---build intrin matrix components---
OffsetPixArray = -CamInfo.PixelSize_m*(CamInfo.NPixels-1)/2;
OffsetLensletArray = -CamInfo.PixelSize_m*CamInfo.NPixels/2 + CamInfo.LensletDiam_m/2;
H_idx_ray = [...
	CamInfo.PixelSize_m,0,   OffsetPixArray; ...
	0,CamInfo.LensletDiam_m, OffsetLensletArray; 0,0,1];
H_abs_rel = [1,0,0; -1/CamInfo.LensletDist_m, 1/CamInfo.LensletDist_m, 0; 0,0,1];
H_to_main = [1, CamInfo.MainLensDist_m, 0; 0,1,0; 0,0,1];
H_mainLens = [1,0,0; -1/CamInfo.MainLensFocal_m,1,0; 0,0,1];

% the ray is expressed at CamInfo.MainLensDist_m; find intersection with each of the st, uv planes
H_abs2pp = [1,STPlanePos_m-CamInfo.MainLensDist_m,0; 1,UVPlanePos_m-CamInfo.MainLensDist_m,0; 0,0,1];
HTot = H_abs2pp*H_mainLens*H_to_main*H_abs_rel*H_idx_ray;

% Solve center ray of each pixel
SUCenters = HTot*P;

%---Solve 4 marginal rays, 2 pixel extents x 2 lenslet extents---
OffsetLensletArrayM1 = OffsetLensletArray - CamInfo.LensletDiam_m/2;
OffsetLensletArrayM2 = OffsetLensletArray + CamInfo.LensletDiam_m/2;
H_idx_rayM1 = [...
	CamInfo.PixelSize_m,0,   OffsetPixArray; ...
	0,CamInfo.LensletDiam_m, OffsetLensletArrayM1; 0,0,1];
H_idx_rayM2 = [...
	CamInfo.PixelSize_m,0,   OffsetPixArray; ...
	0,CamInfo.LensletDiam_m, OffsetLensletArrayM2; 0,0,1];
H_to_lenslet = [1, CamInfo.LensletDist_m, 0; 0,1,0; 0,0,1];
H_lenslet = [1,0,0; -1/CamInfo.LensletFocal_m,1,0; 0,0,1];
H_to_main = [1, CamInfo.MainLensDist_m-CamInfo.LensletDist_m, 0; 0,1,0; 0,0,1];

% can the marginals of the lenslet array be modeled as a single linear operation here? don't see how
% so here we break into 3 steps: with manual adjustment before and after lenslets required, see implementation below
HTot_tolensletM1 = H_to_lenslet*H_abs_rel*H_idx_rayM1;
HTot_tolensletM2 = H_to_lenslet*H_abs_rel*H_idx_rayM2;
HTot_lenslet = H_lenslet;
HTot_afterlenslet = H_abs2pp*H_mainLens*H_to_main;

SUMarginal1 = HTot_tolensletM1*Pm;
SUMarginal2 = HTot_tolensletM2*Pm;

% need to adjust positions to be relative to each ray's corresponding lenslet
LensletCenters_m = Pm(2,:) .* CamInfo.LensletDiam_m + OffsetLensletArray; 

SUMarginal1(1,:) = SUMarginal1(1,:) - LensletCenters_m;
SUMarginal2(1,:) = SUMarginal2(1,:) - LensletCenters_m;

SUMarginal1 = HTot_lenslet*SUMarginal1;
SUMarginal2 = HTot_lenslet*SUMarginal2;

SUMarginal1(1,:) = SUMarginal1(1,:) + LensletCenters_m;
SUMarginal2(1,:) = SUMarginal2(1,:) + LensletCenters_m;

SUMarginal1 = HTot_afterlenslet*SUMarginal1;
SUMarginal2 = HTot_afterlenslet*SUMarginal2;

%---
CamIntrins.H = HTot;


