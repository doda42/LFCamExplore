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

function DrawCameraGeom( CamInfo, CamIntrins, SUSamples )

%---Draw camera geom---
FigHandle = LFFigure(102);

%---Detect first run so we can set up window and legend only once---
UserData = get(FigHandle, 'UserData');  % matlab windows have no user data on creation
FirstRun = isempty(UserData);

%---window size / pos on first run---
if( FirstRun )
	%---change shape of window to 4-wide---
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
	% and center the window horizontally
	WinPos(1) = floor((ScreenSize(3) - WinPos(3))/2) + 1;
	set(FigHandle,'Position', WinPos);
end

%---scale constants adjust with window resize---
subplot(141);

cla
hold on
grid on
plot([0,0],CamInfo.SensorSize_m.*[-0.5,0.5],'w-', 'linewidth',2);  % sensor
plot(CamInfo.LensletDist_m.*[1,1],CamInfo.SensorSize_m.*[-0.5,0.5],'c', 'linewidth',2); % lenslets

Plen2Dist = 0;
if( ~isempty(CamInfo.Plen2FocDist_m) )
	Plen2Dist = CamInfo.Plen2FocDist_m;
	plot(CamInfo.Plen2FocDist_m.*[1,1],[0,0],'wo'); % virtual image within camera
end

ax=axis;
ax(1) = min([0, CamInfo.LensletDist_m, Plen2Dist]).*1.1;
ax(2) = max([CamInfo.LensletDist_m, Plen2Dist]).*1.1;
ax(3:4) = CamInfo.SensorSize_m/2 .* [-1.1,1.1];
axis(ax);
if( abs(CamIntrins.STPlanePos_m) <= ax(2))
	MaxS = max(SUSamples(1,:));
	MaxS = min(MaxS, max(ax(3), -ax(4)));
	
	plot(CamIntrins.STPlanePos_m.*[1,1], ax(3:4), 'g:', 'linewidth',1);
	plot(CamIntrins.STPlanePos_m.*[1,1], MaxS.*[-1,1], 'g-', 'linewidth',2)
end

xlabel('z (m)');
ylabel('x (m)');

ax=axis;
ax(1) = min(ax(1),-ax(2)/50);
axis(ax);
title('Microlenses');

%---Draw main lens geom---
subplot(142);

cla
hold on
grid on
plot([0,0],CamInfo.SensorSize_m.*[-0.5,0.5],'w-', 'linewidth',2);  % sensor
plot(CamInfo.LensletDist_m.*[1,1],CamInfo.SensorSize_m.*[-0.5,0.5],'c', 'linewidth',2); % lenslets

if( ~isempty(CamInfo.Plen2FocDist_m) )
	plot(CamInfo.Plen2FocDist_m.*[1,1],[0,0],'wo'); % virtual image within camera
end

plot(CamInfo.MainLensDist_m.*[1,1],CamInfo.MainLensDiam_m.*[-0.5,0.5],'m', 'linewidth',2); % main lens

ax=axis;
ax(1) = min([0, CamInfo.LensletDist_m, Plen2Dist]).*1.1;
ax(2) = CamInfo.MainLensDist_m + CamInfo.MainLensFocal_m.*1.1;
ax(3:4) = CamInfo.MainLensDiam_m/2 .* [-1.1,1.1];
axis(ax);
if( abs(CamIntrins.STPlanePos_m) <= ax(2))
	MaxS = max(SUSamples(1,:));
	
	plot(CamIntrins.STPlanePos_m.*[1,1], ax(3:4), 'g:', 'linewidth',1);
	plot(CamIntrins.STPlanePos_m.*[1,1], MaxS.*[-1,1], 'g-', 'linewidth',2)
end
xlabel('z (m)');
% 	ylabel('x (m)');

ax=axis;
ax(1) = min(ax(1),-ax(2)/50);
axis(ax);

title('Main Lens');

%---Draw scene geom---
subplot(143);

cla
hold on
grid on
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

ax=axis;
ax(1) = min([0, CamInfo.LensletDist_m, Plen2Dist, CamIntrins.UVPlanePos_m, CamIntrins.STPlanePos_m]).*1.1;
ax(2) = max([CamIntrins.STPlanePos_m, CamIntrins.UVPlanePos_m, CamInfo.MainLensDist_m]) .* 1.1;
ax(3:4) = max([MaxS, MaxU, CamInfo.MainLensDiam_m/2]) .* [-1.1,1.1];
axis(ax);

xlabel('z (m)');

ax=axis;
ax(1) = min(ax(1),-ax(2)/50);
ax(2) = ax(2).*1.05;
axis(ax);
title('Scene');

if( FirstRun )
	%---now draw the legend---
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
	
	set(FigHandle, 'UserData', 'Setup complete')
end

end
