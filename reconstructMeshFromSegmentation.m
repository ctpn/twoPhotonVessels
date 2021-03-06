function reconstruction = reconstructMeshFromSegmentation(binaryStack, path, ...
                            segmentationAlgorithm, reconstructionAlgorithm, isoValue, options, t, ch)

    % Direct import from .mat file if needed
    if nargin == 0
        
        close all
        [~, name] = system('hostname');
        name = strtrim(name); % remove white space
        if strcmp(name, 'C7Pajek') % Petteri   
            path = fullfile('/home', 'petteri', 'Desktop', 'testPM', 'out');
            load(fullfile(path, 'testReconstruction_fullResolution.mat'))        
            load(fullfile(path, 'testReconstruction_halfRes_4slicesOnly.mat'))        
        elseif strcmp(name, 'highschoolintern-MS-7636') % Sharan
            
            path = fullfile('/home/highschoolintern/Desktop/twoPhotonVessels');
            load(fullfile(path, 'testReconstruction.mat'))        
            %load(fullfile(path, 'testReconstruction_halfRes_4slicesOnly.mat'))        
        end
       

    else
        [~, name] = system('hostname');
        name = strtrim(name); % remove white space
        if strcmp(name, 'C7Pajek') % Petteri    
            path = fullfile('/home', 'petteri', 'Desktop', 'testPM', 'out');
            save(fullfile(path, 'testReconstruction.mat'));     
        elseif strcmp(name, '??????') % Sharan
            path = fullfile('testReconstruction.mat');
            save(fullfile(path, 'testReconstruction.mat'));
        end
        
        % if you wanna write to disk
        % export_stack_toDisk(fullfile('figuresOut', 'fullResolution_67slices.tif'), binaryStack)
        
    end
 
        segmentationAlgorithm = 'asets_levelSets';
        reconstructionAlgorithm = 'marchingCubes';
        isoValue = 0.1;
        ch = 1;
        t = 1;
    disp('MESH RECONSTRUCTION from Volumetric Image'); disp('--');
    
    %% INPUT CHECKING
    
        whos
        reconstructFileNameOut = ['meshReconstruct_', segmentationAlgorithm, '_', reconstructionAlgorithm, '_ch', num2str(ch), '_t', num2str(t)];
        debugPlot = false;
    
    %% MESH RECONSTRUCTION
    
    
        %% MARCHING CUBES (Matlab)
        if strcmp(reconstructionAlgorithm, 'marchingCubes')
            
            % Using Marching Cubes algorithm from Matlab FEX
            % http://www.mathworks.com/matlabcentral/fileexchange/32506-marching-cubes
            
            downSampleFactor = [1 1]; % [xy z] downsample to get less vertices/faces
            physicalScaling = [1 1 5]; % physical units of FOV
                                       % TODO, make automagic from metadata
            [F,V] = reconstruct_marchingCubes_wrapper(binaryStack, isoValue, downSampleFactor, physicalScaling, debugPlot);
            % output the faces and vertices
            reconstruction.faces = F;
            reconstruction.vertices = V;
            
           
            
            whos
            dlmwrite('Vertices.mat', V); 
    
        %% MARCHING CUBES (ITK)
        elseif strcmp(reconstructionAlgorithm, 'marchingCubesITK')
            
            % Sharan
            
        else            
            error([reconstructionAlgorithm, '? - What mesh reconstruction algorithm?'])            
        end
    
    %% Condition data

        % triangulate the faces, vertices
        % http://www.mathworks.com/matlabcentral/answers/25865-how-to-export-3d-image-from-matlab-and-import-it-into-maya
        % tr = triangulation(F, V);

        % Delauney, needed for VTK export (?)
        % DT = delaunayTriangulation(tr.Points); 

        % save the reconstruction out as .mat file
        save(fullfile(path, 'reconstructionOut.mat'), 'F', 'V', 'binaryStack');

    %% Point Cloud Library (PCL)
        
        % reconstruction.vertices - point cloud

        % if you want to interface with Point Cloud Library (PCL), see:
        % MATLAB to Point Cloud Library by Peter Corke 
        % http://au.mathworks.com/matlabcentral/fileexchange/40382-matlab-to-point-cloud-library

        
    %% External formats
    
        % STLWrite
        % http://www.mathworks.com/matlabcentral/fileexchange/20922-stlwrite-filename--varargin-
        try
            stlwrite(fullfile(path, [reconstructFileNameOut, '.stl']), F, V)
        catch err
            err
            warning('?')
        end
    
        % Write to OFF (or PLY, SMF, WRL, OBJ) using the Toolbox Graph by 
        % http://www.mathworks.com/matlabcentral/fileexchange/5355-toolbox-graph
        try
            reconstruction.meshOnDisk = fullfile(path, [reconstructFileNameOut, '.off']);
            write_mesh(reconstruction.meshOnDisk, V, F)
        catch err
            err
            warning('?')
        end
        
        % Paraview export (VTK)
        % http://www.mathworks.com/matlabcentral/fileexchange/47814-export-3d-data-to-paraview-in-vtk-legacy-file-format
        x = 1:1:size(binaryStack,1); y = 1:1:size(binaryStack,2); z = 1:1:size(binaryStack,3);
        % size(DT.ConnectivityList)
        % vtkwrite(fullfile('debugMATs', 'reconstructionOut.vtk'), 'polydata','tetrahedron',x,y,z,DT.ConnectivityList);
     
        % as a Wavefront/Alias Obj file
        % http://www.aleph.se/Nada/Ray/matlabobj.html
       
