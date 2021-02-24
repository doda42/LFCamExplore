% DrawSamplingSU - Draws the sampling space of a camera in the epipolar plane
% 
% The display is based on the camera's physical description and intrinsics, and the pixel centers
% and marginal rays as computed by SolveLensPositions and SolveIntrinsicMatrix.
% 
% This is part of LFCamExplore, a tool for building intuition in the design space of plenoptic
% cameras.
% 
% Please see LFCamExploreGUI.m and LFCamExplore.pdf for further information.

% Copyright (c) 2017 Donald G. Dansereau

function DispOptions = DrawSamplingSU( CamInfo, CamIntrins, SUMarginal1, SUMarginal2, DispOptions )

DispOptions = LFDefaultField('DispOptions','DepthRefsEnable', true);
DispOptions = LFDefaultField('DispOptions','KeyDepthRef_m', 1);

%---Derived---
DispOptions.DepthRefs = DispOptions.KeyDepthRef_m .* [1,1, 0.5, 2, inf];
DepthRefColors = [ ...
	[0.8,0.8,0.8]; [1,1,1]; ... % first 2 are key depth and spatially offset
	[0.5,0.8,0.5]; [1,0.5,0.5]; [0.8,0,0] ]; % next 3 are 0.5x, 2x and inf


%---draw in s,u space---
FigHandle = LFFigure(202);

%---Detect first run so we can set up window---
UserData = get(FigHandle, 'UserData');  % matlab windows have no user data on creation
FirstRun = isempty(UserData);

%---on first run set window position---
if( FirstRun )
	clf

	drawnow
	movegui(FigHandle,'north');
	
	hold on
	grid on
	xlabel('s (m)');
	ylabel('u (m)');
	title('Sampling Pattern');
	
	set(FigHandle, 'UserData', 'Setup complete')
end

%---Clear / set up figure---
cla

% draw pixel patches
for( iPix = 1:CamInfo.PixelsPerLenslet )
	for( iLenslet = 1:CamInfo.NLenslets )
		PIdx = iPix + (iLenslet-1)*(CamInfo.PixelsPerLenslet+1);
		DrawPts = [SUMarginal1(1:2,PIdx), SUMarginal2(1:2,PIdx), SUMarginal2(1:2,PIdx+1), SUMarginal1(1:2,PIdx+1)];
		
		% unique colour patches
		Hue = mod((iPix*2347 + iLenslet*98665) / 37, 1); %pseudorandom but repeatable patch colours
		Val = 0.9*(1.5-mod(iLenslet,2))/1.5;
		Sat = 0.8*(2-mod(iPix,2))/2;
		DrawColor = hsv2rgb( Hue, Sat, Val );
		
		patch( DrawPts(1,:), DrawPts(2,:), DrawColor, 'LineStyle','none' );
	end
end

%---autoscale display---
if( DispOptions.AxesFollowSU )
	ax(1:2) = max(abs([SUMarginal1(1,:), SUMarginal2(1,:)])) .* [-1.1,1.1];
	ax(3:4) = max(abs([SUMarginal1(2,:), SUMarginal2(2,:)])) .* [-1.1,1.1];
	axis(ax);
else
	ax = axis;
end

if( DispOptions.DepthRefsEnable )
	% draw depth references
	Pz = DispOptions.DepthRefs;
	Px = [1e-3, 0, 0, 0, 0]; % always 1 mm for now
	CamInfo.D = CamIntrins.UVPlanePos_m - CamIntrins.STPlanePos_m;
	Pz = Pz - CamIntrins.STPlanePos_m;
	
	s1 = ax(1);
	s2 = ax(2);
	
	for( iLine = 1:length(Pz) )
		CurDrawColor = DepthRefColors(iLine,:);
		u1 = CamInfo.D / Pz(iLine) * (Px(iLine) - s1) + s1;
		u2 = CamInfo.D / Pz(iLine) * (Px(iLine) - s2) + s2;
		line( [s1,s2], [u1,u2], 'color', CurDrawColor, 'LineWidth',2);
		
		if( iLine > 1 )  % don't print for 1mm ref
			plot(s2,u2,'.','markersize',20,'color',CurDrawColor);
			if( u2>=ax(3) && u2<ax(4) )
				if( iLine < length(DispOptions.DepthRefs) )
					FormatStr = '%.2gm';
				else
					FormatStr = '%.2g';
				end
				text(s2.*1.05,u2, sprintf(FormatStr,DispOptions.DepthRefs(iLine)),'color',CurDrawColor);
			end
		else
			text(s1 + (s2-s2)/10, u1 + (ax(4)-ax(3))/40, '+1mm','color',[1,1,1],'fontweight','bold');
		end
	end
end

end
