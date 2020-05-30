classdef MeasIdVel < navsu.internal.MeasID
    properties (SetObservable = true)       
        id = 255;
        
        xyz  navsu.internal.MeasEnum;
    end
    
    
    methods
        function obj = MeasIdVel(id,xyz)
            
            % Instantiate the array of the super class
            obj = obj@navsu.internal.MeasID(repelem(navsu.internal.MeasEnum.Velocity,...
                size(id,1),size(id,2)));
            for idx = 1:size(id,1)
                for jdx = 1:size(id,2)
                    
                    obj(idx,jdx).TypeID = navsu.internal.MeasEnum.Velocity;
                    
                    obj(idx,jdx).id = id(idx,jdx);
                    
                    obj(idx,jdx).xyz = xyz(idx,jdx);
                    
                     obj(idx,jdx).idVec = permute([double(navsu.internal.MeasEnum.Velocity) ...
                        id(idx,jdx) double(xyz(idx,jdx)) 0 0 0],[1 3 2]);   
                end
            end
        end
    end
    
    
end









