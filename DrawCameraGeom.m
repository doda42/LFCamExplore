% DrawCameraGeom - Draws the physical layout of the camera
% 
% The display is based on the camera's physical description as computed by SolveLensPositions. It's
% pretty minimal right now but could be easily extended to draw main lens and lenslets as ovals and
% pixels as patches.
% 
% This is part of LFCamExplore, a tool for building intuition in the design space of plenoptic
% cameras.
% 
% Please see LFCamExploreGUI.m and LFCamExplore.pdf for further information.

% Copyright (c) 2017 Donald G. Dansereau

function DrawCameraGeom( CamInfo, CamIntrins, SUSamples, DispOptions )

%---Draw camera geom---
FigHandle = LFFigure(102);

%---Detect first run so we can set up window and legend only once---
UserData = get(FigHandle, 'UserData');  % matlab windows have no user data on creation
FirstRun = isempty(UserData);

%---window size / pos and legend on first run---
if( FirstRun )
	%---set up labels, axes---
	% doing this only once at creation improves speed
	subplot(141);
	cla
	hold on
	grid on
	xlabel('z (m)');
	ylabel('x (m)');
	title('Microlenses');
	
	subplot(142);
	cla
	hold on
	grid on
	xlabel('z (m)');
	title('Main Lens');
	
	subplot(143);
	cla
	hold on
	grid on
	xlabel('z (m)');
	title('Scene');

	%---draw the legend---
	subplot(144);
	cla
	hold on
	
	OverviewColours = {'w','c','wo','m','g:','g','y'};
	LegendTxt = {'Sensor','Lenslets','Plen2 focus', 'Main lens', 'ST plane','ST coverage', 'UV plane'};
	
	for( iCol = 1:length(OverviewColours) )
		CurCol = OverviewColours{iCol};
		CurTxt = LegendTxt{iCol};
		plot( [0.1,0.4], -iCol.*[1,1], CurCol, 'linewidth',2 );
	end
	axis([-10,0,-10,0]);
	axis off
	legend( LegendTxt );

	%---change shape of window to 5-wide---
	drawnow % needed to make the window establish its initial bounds
	DefaultOuterDims = get(FigHandle,'OuterPosition'); % record default window size including toolbars
	WinPos = get(FigHandle,'Position');
	WinPos(3) = WinPos(4) * 5;
	
	%---make sure window is within screen---
	ScreenSize = get(0,'screensize');
	WinWidth = WinPos(3);
	WinScale = 1;
	if(WinWidth > ScreenSize(3))
		WinScale = ScreenSize(3)/WinWidth * 0.8;
		WinPos(3:4) = floor(WinPos(3:4) * WinScale);
	end
	% center the window horizontally and set to bottom of window
	WinPos(1) = floor((ScreenSize(3) - WinPos(3))/2) + 1;
	WinPos(2) = 0;
	set(FigHandle,'Position', WinPos);
	
	% get new window outer dims including toolbars, and shift to just below s,u display
	% assumes s,u display maintained its default vertical size DefaultOuterDims(4)
	ScaledOuterDims = get(FigHandle,'OuterPosition');
	WinPos(2) = ScreenSize(4) - ScaledOuterDims(4) - DefaultOuterDims(4);
	set(FigHandle,'Position', WinPos);

	set(FigHandle, 'UserData', 'Setup complete')
end

%---scale constants adjust with window resize---
subplot(141);
cla

plot([0,0],CamInfo.SensorSize_m.*[-0.5,0.5],'w-', 'linewidth',2);  % sensor
plot(CamInfo.LensletDist_m.*[1,1],CamInfo.SensorSize_m.*[-0.5,0.5],'c', 'linewidth',2); % lenslets

Plen2Dist = 0;
if( ~isempty(CamInfo.Plen2FocDist_m) )
	Plen2Dist = CamInfo.Plen2FocDist_m;
	plot(CamInfo.Plen2FocDist_m.*[1,1],[0,0],'wo'); % virtual image within camera
end

ax(2) = max([CamInfo.LensletDist_m, Plen2Dist]).*1.1;
ax(1) = min([-ax(2)/50, CamInfo.LensletDist_m, Plen2Dist]).*1.1;
ax(3:4) = CamInfo.SensorSize_m/2 .* [-1.1,1.1];
if( ~DispOptions.FastRender )
	axis(ax);
end
if( abs(CamIntrins.STPlanePos_m) <= ax(2))
	MaxS = max(SUSamples(1,:));
	MaxS = min(MaxS, max(ax(3), -ax(4)));
	
	plot(CamIntrins.STPlanePos_m.*[1,1], ax(3:4), 'g:', 'linewidth',1);
	plot(CamIntrins.STPlanePos_m.*[1,1], MaxS.*[-1,1], 'g-', 'linewidth',2)
end

%---Draw main lens geom---
subplot(142);
cla

plot([0,0],CamInfo.SensorSize_m.*[-0.5,0.5],'w-', 'linewidth',2);  % sensor
plot(CamInfo.LensletDist_m.*[1,1],CamInfo.SensorSize_m.*[-0.5,0.5],'c', 'linewidth',2); % lenslets

if( ~isempty(CamInfo.Plen2FocDist_m) )
	plot(CamInfo.Plen2FocDist_m.*[1,1],[0,0],'wo'); % virtual image within camera
end

plot(CamInfo.MainLensDist_m.*[1,1],CamInfo.MainLensDiam_m.*[-0.5,0.5],'m', 'linewidth',2); % main lens

ax(2) = CamInfo.MainLensDist_m + CamInfo.MainLensFocal_m.*1.1;
ax(1) = min([-ax(2)/50, CamInfo.LensletDist_m, Plen2Dist]).*1.1;
ax(3:4) = CamInfo.MainLensDiam_m/2 .* [-1.1,1.1];
if( ~DispOptions.FastRender )
	axis(ax);
end
if( abs(CamIntrins.STPlanePos_m) <= ax(2))
	MaxS = max(SUSamples(1,:));
	
	plot(CamIntrins.STPlanePos_m.*[1,1], ax(3:4), 'g:', 'linewidth',1);
	plot(CamIntrins.STPlanePos_m.*[1,1], MaxS.*[-1,1], 'g-', 'linewidth',2)
end

%---Draw scene geom---
subplot(143);
cla

plot([0,0],CamInfo.SensorSize_m.*[-0.5,0.5],'w-', 'linewidth',2);  % sensor
plot(CamInfo.LensletDist_m.*[1,1],CamInfo.SensorSize_m.*[-0.5,0.5],'c', 'linewidth',2); % lenslets

if( ~isempty(CamInfo.Plen2FocDist_m) )
	plot(CamInfo.Plen2FocDist_m.*[1,1],[0,0],'wo'); % virtual image within camera
end

plot(CamInfo.MainLensDist_m.*[1,1],CamInfo.MainLensDiam_m.*[-0.5,0.5],'m', 'linewidth',2); % main lens

%--st plane--
MaxU = max(SUSamples(2,:));
MaxS = max(SUSamples(1,:));
plot(CamIntrins.STPlanePos_m.*[1,1], MaxU.*[-1,1], 'g:', 'linewidth',1)
plot(CamIntrins.STPlanePos_m.*[1,1], MaxS.*[-1,1], 'g-', 'linewidth',2)
plot(CamIntrins.UVPlanePos_m.*[1,1], MaxU.*[-1,1], 'y-', 'linewidth',2)

if( ~DispOptions.FastRender )
	ax(2) = max([CamIntrins.STPlanePos_m, CamIntrins.UVPlanePos_m, CamInfo.MainLensDist_m]) .* 1.1;
	ax(1) = min([-ax(2)/50, CamInfo.LensletDist_m, Plen2Dist, CamIntrins.UVPlanePos_m, CamIntrins.STPlanePos_m]).*1.1;
	ax(3:4) = max([MaxS, MaxU, CamInfo.MainLensDiam_m/2]) .* [-1.1,1.1];
	axis(ax);
end

end
