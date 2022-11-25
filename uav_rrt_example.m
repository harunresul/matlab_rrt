clc; clear;

% Set RNG seed for repeatable result
rng(1,"twister");

mapData = load("uavMapCityBlock.mat","omap");
omap = mapData.omap;
% Consider unknown spaces to be unoccupied
omap.FreeThreshold = omap.OccupiedThreshold;

startPose = [12 22 25 pi/2];
goalPose = [150 200 55 -pi/2];
figure("Name","StartAndGoal")
hMap = show(omap);
hold on
scatter3(hMap,startPose(1),startPose(2),startPose(3),30,"red","filled")
scatter3(hMap,goalPose(1),goalPose(2),goalPose(3),30,"green","filled")
hold off
view([-31 63])


% Define the State Space Object
ss = ExampleHelperUAVStateSpace("MaxRollAngle",pi/6,...
                                "AirSpeed",6,...
                                "FlightPathAngleLimit",[-0.2 0.2],...
                                "Bounds",[-20 220; -20 220; 10 100; -pi pi]);

threshold = [(goalPose-0.5)' (goalPose+0.5)'; -pi pi];


% Use the setWorkspaceGoalRegion function to update the goal pose and the region around it
setWorkspaceGoalRegion(ss,goalPose,threshold)


% Define the State Validator Object
sv = validatorOccupancyMap3D(ss,"Map",omap);
sv.ValidationDistance = 0.1;



% Set Up the RRT Path Planner
planner = plannerRRT(ss,sv);
planner.MaxConnectionDistance = 50;
planner.GoalBias = 0.10;  
planner.MaxIterations = 400;
planner.GoalReachedFcn = @(~,x,y)(norm(x(1:3)-y(1:3)) < 5);


% Execute Path Planning
[pthObj,solnInfo] = plan(planner,startPose,goalPose);


% % Simulate a UAV Following the Planned Path
% if (solnInfo.IsPathFound)
%     figure("Name","OriginalPath")
%     % Visualize the 3-D map
%     show(omap)
%     hold on
%     scatter3(startPose(1),startPose(2),startPose(3),30,"red","filled")
%     scatter3(goalPose(1),goalPose(2),goalPose(3),30,"green","filled")
%     
%     interpolatedPathObj = copy(pthObj);
%     interpolate(interpolatedPathObj,1000)
%     
%     % Plot the interpolated path based on UAV Dubins connections
%     hReference = plot3(interpolatedPathObj.States(:,1), ...
%         interpolatedPathObj.States(:,2), ...
%         interpolatedPathObj.States(:,3), ...
%         "LineWidth",2,"Color","g");
%     
%     % Plot simulated UAV trajectory based on fixed-wing guidance model
%     % Compute total time of flight and add a buffer
%     timeToReachGoal = 1.05*pathLength(pthObj)/ss.AirSpeed;
%     waypoints = interpolatedPathObj.States;
%     [xENU,yENU,zENU] = exampleHelperSimulateUAV(waypoints,ss.AirSpeed,timeToReachGoal);
%     hSimulated = plot3(xENU,yENU,zENU,"LineWidth",2,"Color","r");
%     legend([hReference,hSimulated],"Reference","Simulated","Location","best")
%     hold off
%     view([-31 63])
% end



% Smooth Dubins Path and Simulate UAV Trajectory
if (solnInfo.IsPathFound)
    smoothWaypointsObj = exampleHelperUAVPathSmoothing(ss,sv,pthObj);
    
    figure("Name","SmoothedPath")
    % Plot the 3-D map
    show(omap)
    hold on
    scatter3(startPose(1),startPose(2),startPose(3),30,"red","filled")
    scatter3(goalPose(1),goalPose(2),goalPose(3),30,"green","filled")
    
    interpolatedSmoothWaypoints = copy(smoothWaypointsObj);
    interpolate(interpolatedSmoothWaypoints,1000)
    
    % Plot smoothed path based on UAV Dubins connections
    hReference = plot3(interpolatedSmoothWaypoints.States(:,1), ...
        interpolatedSmoothWaypoints.States(:,2), ...
        interpolatedSmoothWaypoints.States(:,3), ...
        "LineWidth",2,"Color","g");
    
    % Plot simulated flight path based on fixed-wing guidance model
    waypoints = interpolatedSmoothWaypoints.States;
    timeToReachGoal = 1.05*pathLength(smoothWaypointsObj)/ss.AirSpeed;
    [xENU,yENU,zENU] = exampleHelperSimulateUAV(waypoints,ss.AirSpeed,timeToReachGoal);
    hSimulated = plot3(xENU,yENU,zENU,"LineWidth",2,"Color","r");
    
    legend([hReference,hSimulated],"SmoothedReference","Simulated","Location","best")
    hold off
    view([-31 63]);
end




