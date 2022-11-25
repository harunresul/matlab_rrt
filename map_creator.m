function scene = map_creator()
    
    map_size = 1000;
    danger_zones = [100 100 100 100;
                    250 200 50 200];
    
    simTime = 60;    % in seconds
    updateRate = 2;  % in Hz
    scene = uavScenario("UpdateRate",updateRate,"StopTime",simTime); 
    
    
    % Floor 
    addMesh(scene, "Polygon",{[-map_size map_size;-map_size -map_size;map_size -map_size;map_size map_size],[-1 0]},[0.36 0.44 0.09]); 


    
    % Features
    for i=1:height(danger_zones) % number of rows
        addMesh(scene,"Cylinder", {[danger_zones(i,1) danger_zones(i,2) danger_zones(i,3)], [0 danger_zones(i,4)]}, [0.83 0.23 0.23]);
    end

    show3D(scene);
    axis equal
    view([-115 20])
    

end