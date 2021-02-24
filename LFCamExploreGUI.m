% LFCamExploreGUI.m: A tool for building intuition in the design space of plenoptic cameras.
% 
% This interactive tool allows you to manipulate camera design parameters and visualize the
% resulting changes in sampling patterns.  A few example configurations are included, and a tutorial
% on sampling patterns is included in the accompanying documentation.
% 
% Please see LFCamExplore.pdf for further information.

% Copyright (c) 2017 Donald G. Dansereau

function LFCamExploreGUI
colordef black;

%---globals---
global gLock;

%---Default UI settings---
GuiOptions.TBarWidth = 340;
GuiOptions.DarkBG = [0.05,0.1,0.1];
GuiOptions.BG = [38,38,38]/256;
GuiOptions.IntrinDispOptions.STPlanePos_m = 0;
GuiOptions.IntrinDispOptions.UVPlanePos_m = 1;
GuiOptions.IntrinDispOptions.KeyDepthRef_m = 1;

%---default camera---
CamInfo = LFReadMetadata('CamConfigs/ToyPlen2.json');

%---Build the GUI---
UIElements = SetupGUI( GuiOptions, CamInfo );

%---Kick the GUI to update once---
gLock = [];
notify( UIElements(2), 'ContinuousValueChange' );

end

%-----------------------------------------------------------------
% Main update routine, called any time a GUI object changes
function DepthSliderCallback(~, ~, UIElements)

%---Update CamInfo with UI control values---
[CamInfo, GuiOptions] = UpdateCamInfoFromUI( UIElements );
%---Selectively enable/disable UI elements and update UI strings with CamInfo---
UpdateUIFromCamInfo( CamInfo, UIElements, GuiOptions );

%---Skip rendering if we're already rendering a previous frame---
global gLock;
if( isempty(gLock) )
	gLock = true;
else
	return;
end

%---Recompute lens positions based on GUI settings---
[CamInfo, CamValid] = SolveLensPositions( CamInfo );

%---Additional checks on camera validity---
if( CamInfo.NPixels < CamInfo.PixelsPerLenslet )
	CamValid = false;
end

%---Find sampling pattern---
if( CamValid )
	%---Find intrinsics and sampling patterns (including marginals) of camera---
	[CamIntrins, SUCenters, SUMarginal1, SUMarginal2, DispOptions] = SolveIntrinsicMatrix( CamInfo, GuiOptions.IntrinDispOptions );
 	
	%---Draw sampling pattern in SU---
	DispOptions = DrawSamplingSU( CamInfo, CamIntrins, SUMarginal1, SUMarginal2, DispOptions );

	%---Draw Camera geometry---
	DrawCameraGeom( CamInfo, CamIntrins, SUCenters );

	%---Estimate performance of camera---
	CamPerformance = SolveCamPerformance( CamInfo );
	fprintf('\n---Warning: performance metrics are experimental---\n');
	disp(CamInfo);
	fprintf('\n');
	disp(CamPerformance);
	
	%---Update UI elements---
	UIElements(10).UserData.hTextDisplay.String = sprintf('ST Plane Pos (m): %.2f', CamIntrins.STPlanePos_m);
	UIElements(12).UserData.hTextDisplay.String = sprintf('UV Plane Pos (m): %.2f', CamIntrins.UVPlanePos_m);
	
	if( UIElements(15).Value )
		UIElements(14).UserData.hTextDisplay.String = ['Depth refs (m): ', sprintf('%.2f, ', unique(DispOptions.DepthRefs))];
	else
		UIElements(14).UserData.hTextDisplay.String = 'Depth refs';
	end
else
	LFFigure(202);
	cla
	warning('invalid camera params -- SolveLensPositions failed');
end

%---
drawnow
gLock = [];
end

%-------------------------------------------------------
function UIElements = SetupGUI( GuiOptions, CamInfo )

%---Set up the main window---
FigHandle = LFFigure(101);

%---Detect first run so we can set up window---
UserData = get(FigHandle, 'UserData');  % matlab windows have no user data on creation
FirstRun = isempty(UserData);

clf
set(FigHandle, 'menubar', 'none');
axes('Units','pixels');
colormap gray
axis off

%---window size / pos on first run---
if( FirstRun )
	movegui( FigHandle, 'northwest' );
end

WinPos = get(gca,'OuterPosition');
YPos = WinPos(4);
ButtonHeight = 25;

%--- camera model ---
YPos = YPos - ButtonHeight;
uicontrol('Style', 'text', 'String', 'Camera Model', 'Position', [10 YPos-3 300 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hCamModel = uicontrol('Style', 'popup', 'String', {'Plen1', 'Plen2'}, 'Position', [20 YPos 80 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
switch( CamInfo.CameraModel )
	case 'Plen1'
		hCamModel.Value = 1;
	case 'Plen2'
		hCamModel.Value = 2;
end

%--- load / save buttons---
hSaveButton = uicontrol('Style', 'pushbutton', 'String', 'Save', 'Position', [GuiOptions.TBarWidth YPos 80 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
hLoadButton = uicontrol('Style', 'pushbutton', 'String', 'Load', 'Position', [GuiOptions.TBarWidth+100 YPos 80 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);

%---Cam settings---
YPos = YPos - ButtonHeight; % gap

YPos = YPos - ButtonHeight;
hFocDepthTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hFocDepth = uicontrol('Style', 'slider', 'Min', 0.01,'Max',20,'Value',CamInfo.FocalDepth_m, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hFocDepth, 0.1 );
set( hFocDepth, 'UserData', struct('hTextDisplay', hFocDepthTxt) );

YPos = YPos - ButtonHeight;
hPlen2FocRatioTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hPlen2FocRatio = uicontrol('Style', 'slider', 'Min', -25,'Max',25,'Value',CamInfo.Plen2FocRatio, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hPlen2FocRatio, 0.1 );
set( hPlen2FocRatio, 'UserData', struct('hTextDisplay', hPlen2FocRatioTxt) );

YPos = YPos - ButtonHeight;
hPixelsPerLensletTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hPixelsPerLenslet = uicontrol('Style', 'slider', 'Min', 1,'Max',200,'Value',CamInfo.PixelsPerLenslet, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hPixelsPerLenslet, 1 );
set( hPixelsPerLenslet, 'UserData', struct('hTextDisplay', hPixelsPerLensletTxt) );

YPos = YPos - ButtonHeight;
hMainLensFocal_mTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hMainLensFocal_m = uicontrol('Style', 'slider', 'Min', 1,'Max',100,'Value',1e3*CamInfo.MainLensFocal_m, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
set( hMainLensFocal_m, 'UserData', struct('hTextDisplay', hMainLensFocal_mTxt) );

YPos = YPos - ButtonHeight;
hLensletFocal_mTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hLensletFocal_m = uicontrol('Style', 'slider', 'Min', 1,'Max',3000,'Value',1e6*CamInfo.LensletFocal_m, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hLensletFocal_m, 1 );
set( hLensletFocal_m, 'UserData', struct('hTextDisplay', hLensletFocal_mTxt) );

YPos = YPos - ButtonHeight;
hNPixTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hNPix = uicontrol('Style', 'slider', 'Min', 2,'Max',4096,'Value',CamInfo.NPixels, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hNPix, 1 );
set( hNPix, 'UserData', struct('hTextDisplay', hNPixTxt) );

YPos = YPos - ButtonHeight;
hPixSizeTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hPixSize = uicontrol('Style', 'slider', 'Min', 0.1,'Max',50,'Value',1e6*CamInfo.PixelSize_m, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hPixSize, 0.1 );
set( hPixSize, 'UserData', struct('hTextDisplay', hPixSizeTxt) );

%--- Display / ui controls ---
YPos = YPos - ButtonHeight;

YPos = YPos - ButtonHeight;
hSTFollowCam = uicontrol('String','ST Plane Follows Camera', 'Style', 'checkbox','Value',1, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.BG,'ForegroundColor',0.7.*[1,1,1]);

hAxesFollowSU = uicontrol('String','SU axes autoscale', 'Style', 'checkbox','Value',1, 'Position', [2/3*GuiOptions.TBarWidth YPos 2/3*GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.BG,'ForegroundColor',0.7.*[1,1,1]);

YPos = YPos - ButtonHeight;
hSTPosTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hSTPos = uicontrol('Style', 'slider', 'Min', -0.5,'Max',10,'Value',GuiOptions.IntrinDispOptions.STPlanePos_m, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hSTPos, 1e-3 );
set( hSTPos, 'UserData', struct('hTextDisplay', hSTPosTxt) );

YPos = YPos - ButtonHeight;
hUVFollowCam = uicontrol('String','UV Plane Follows Camera', 'Style', 'checkbox','Value',1, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.BG,'ForegroundColor',0.7.*[1,1,1]);

YPos = YPos - ButtonHeight;
hUVPosTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [GuiOptions.TBarWidth+20 YPos-3 180 20], 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
hUVPos = uicontrol('Style', 'slider', 'Min', -0.5,'Max',10,'Value',GuiOptions.IntrinDispOptions.UVPlanePos_m, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hUVPos, 0.1 );
set( hUVPos, 'UserData', struct('hTextDisplay', hUVPosTxt) );

YPos = YPos - ButtonHeight;
hDepthRefEnable = uicontrol('Style', 'checkbox','Value',1, 'Position', [20 YPos 80 20], 'BackgroundColor',GuiOptions.BG,'ForegroundColor',0.7.*[1,1,1]);
hDepthRefPosTxt = uicontrol('Style', 'text', 'String', '0', 'Position', [40 YPos-3 GuiOptions.TBarWidth+20 20], 'HorizontalAlignment', 'left', 'BackgroundColor',0.15.*[1,1,1],'ForegroundColor',0.7.*[1,1,1]);
YPos = YPos - ButtonHeight;
hDepthRefPos = uicontrol('Style', 'slider', 'Min', 0.1,'Max',20,'Value',GuiOptions.IntrinDispOptions.KeyDepthRef_m, 'Position', [20 YPos GuiOptions.TBarWidth 20], 'BackgroundColor',GuiOptions.DarkBG,'ForegroundColor',0.7.*[1,1,1]);
FixSliderStep( hDepthRefPos, 0.1 );
set( hDepthRefPos, 'UserData', struct('hTextDisplay', hDepthRefPosTxt) );

%---Build an array of all the control handles---
UIElements = [hCamModel, hFocDepth, hPlen2FocRatio, hPixelsPerLenslet, hMainLensFocal_m, hLensletFocal_m, hNPix, hPixSize, hSTFollowCam,hSTPos, hUVFollowCam,hUVPos, hAxesFollowSU, hDepthRefPos, hDepthRefEnable];

%---Set up the callbacks---
UpdateFunc = @(src,evnt) DepthSliderCallback(src,evnt, UIElements);
SaveButtonFunc = @(hObj, event) SaveButtonCallback(hObj, event, UIElements );
LoadButtonFunc = @(hObj, event) LoadButtonCallback(hObj, event, GuiOptions);

addlistener(hFocDepth, 'ContinuousValueChange', UpdateFunc);
addlistener(hPlen2FocRatio, 'ContinuousValueChange', UpdateFunc);
addlistener(hPixelsPerLenslet, 'ContinuousValueChange', UpdateFunc);
addlistener(hMainLensFocal_m, 'ContinuousValueChange', UpdateFunc);
addlistener(hLensletFocal_m, 'ContinuousValueChange', UpdateFunc);
addlistener(hNPix, 'ContinuousValueChange', UpdateFunc);
addlistener(hPixSize, 'ContinuousValueChange', UpdateFunc);
addlistener(hDepthRefPos, 'ContinuousValueChange', UpdateFunc);
addlistener(hSTPos, 'ContinuousValueChange', UpdateFunc);
addlistener(hUVPos, 'ContinuousValueChange', UpdateFunc);

set(hCamModel, 'Callback', UpdateFunc);
set(hFocDepth, 'Callback', UpdateFunc);
set(hPlen2FocRatio, 'Callback', UpdateFunc);
set(hPixelsPerLenslet, 'Callback', UpdateFunc);
set(hMainLensFocal_m, 'Callback', UpdateFunc);
set(hLensletFocal_m, 'Callback', UpdateFunc);
set(hNPix, 'Callback', UpdateFunc);
set(hPixSize, 'Callback', UpdateFunc);
set(hDepthRefPos, 'Callback', UpdateFunc);
set(hSTFollowCam, 'Callback', UpdateFunc);
set(hSTPos, 'Callback', UpdateFunc);
set(hUVFollowCam, 'Callback', UpdateFunc);
set(hDepthRefEnable, 'Callback', UpdateFunc);
set(hUVPos, 'Callback', UpdateFunc);
set(hAxesFollowSU, 'Callback', UpdateFunc);
set(hSaveButton, 'Callback', SaveButtonFunc);
set(hLoadButton, 'Callback', LoadButtonFunc);

%---
if( FirstRun )
	set(FigHandle, 'UserData', 'Setup complete')
end

end

%-------------------------------------------------------
function SaveButtonCallback(~, ~, UIElements)
CamInfo = UpdateCamInfoFromUI( UIElements );
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
CamInfo.GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFCamExploreVersion );

[FName, Path] = uiputfile(fullfile('CamConfigs','*.json'));
LFWriteMetadata( fullfile(Path, FName), CamInfo );
end

%-------------------------------------------------------
function LoadButtonCallback(~, ~, GuiOptions)
global gLock;

[FName, Path] = uigetfile(fullfile('CamConfigs','*.json'));
CamInfo = LFReadMetadata( fullfile(Path, FName) );

%---Rebuild the GUI---
UIElements = SetupGUI( GuiOptions, CamInfo );

%---Kick the GUI to update once---
gLock = [];
notify( UIElements(2), 'ContinuousValueChange' );
end

%-------------------------------------------------------
function FixSliderStep( hGuiObj, StepSize )
set(hGuiObj, 'SliderStep', [StepSize / (hGuiObj.Max-hGuiObj.Min), StepSize / (hGuiObj.Max-hGuiObj.Min)]);
end

%-------------------------------------------------------
function [CamInfo, GuiOptions] = UpdateCamInfoFromUI( UIElements )
% UIElements = [hCamModel, hFocDepth, hPlen2FocRatio, hPixelsPerLenslet, hMainLensFocal_m, hLensletFocal_m, hNPix, hPixSize, hSTFollowCam,hSTPos, hUVFollowCam,hUVPos, hAxesFollowSU, hDepthRefPos, hDepthRefEnable];
%---Get all control values to build a CamInfo structure---
CamInfo.CameraModel = UIElements(1).String{UIElements(1).Value};
CamInfo.FocalDepth_m = UIElements(2).Value;
CamInfo.Plen2FocRatio = UIElements(3).Value;
CamInfo.PixelsPerLenslet = round(UIElements(4).Value);
CamInfo.MainLensFocal_m = 1e-3*UIElements(5).Value;
CamInfo.LensletFocal_m = 1e-6*UIElements(6).Value;
CamInfo.NPixels = round(UIElements(7).Value);
CamInfo.PixelSize_m = 1e-6*UIElements(8).Value;

GuiOptions.IntrinDispOptions.STFollowsCamPlane = UIElements(9).Value;
GuiOptions.IntrinDispOptions.STPlanePos_m = UIElements(10).Value;
GuiOptions.IntrinDispOptions.UVFollowsCamPlane = UIElements(11).Value;
GuiOptions.IntrinDispOptions.UVPlanePos_m = UIElements(12).Value;
GuiOptions.IntrinDispOptions.AxesFollowSU = UIElements(13).Value;
GuiOptions.IntrinDispOptions.KeyDepthRef_m = UIElements(14).Value;
GuiOptions.IntrinDispOptions.DepthRefsEnable = UIElements(15).Value;
end

%-------------------------------------------------------
function UpdateUIFromCamInfo( CamInfo, UIElements, GuiOptions )
%---Echo values out to display---
UIElements(2).UserData.hTextDisplay.String = sprintf('Focal depth (m): %.2f', CamInfo.FocalDepth_m);
UIElements(4).UserData.hTextDisplay.String = sprintf('Lenslet diam (pix): %g', CamInfo.PixelsPerLenslet);
UIElements(5).UserData.hTextDisplay.String = sprintf('Main focal (mm): %.2f', 1e3*CamInfo.MainLensFocal_m);
UIElements(6).UserData.hTextDisplay.String = sprintf('Lenslet focal (um): %.2f', 1e6*CamInfo.LensletFocal_m);
UIElements(7).UserData.hTextDisplay.String = sprintf('Pixel count: %g', CamInfo.NPixels);
UIElements(8).UserData.hTextDisplay.String = sprintf('Pix size (um): %.2f', 1e6*CamInfo.PixelSize_m);

%---selectively disable elements---
DisableUIElement( UIElements(10), ~GuiOptions.IntrinDispOptions.STFollowsCamPlane );
DisableUIElement( UIElements(12), ~GuiOptions.IntrinDispOptions.UVFollowsCamPlane );
DisableUIElement( UIElements(14), GuiOptions.IntrinDispOptions.DepthRefsEnable );

switch( CamInfo.CameraModel )
	case 'Plen2'
		UIElements(3).Enable = 'on';
		UIElements(3).UserData.hTextDisplay.String = sprintf('Plen2 ratio: %.2f', CamInfo.Plen2FocRatio);
	otherwise
		UIElements(3).Enable = 'off';
		UIElements(3).UserData.hTextDisplay.String = sprintf('[Plen2 ratio]');
end
end


function DisableUIElement( UIElement, Enable )
if( Enable )
	UIElement.Enable = 'on';
else
	UIElement.Enable = 'off';
end
end
