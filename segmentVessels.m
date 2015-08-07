function [segmentationStack, mask] = segmentVessels(imageStack, vesselnessStack, segmentationAlgorithm, options, t, ch)
    
    %% INPUT CHECKS
    
        options.segmImageOutBase = ['segmentationProgress_', segmentationAlgorithm, ...
                                    '_ch', num2str(ch), '_t', num2str(t)];

    %% SEGMENTATION
        
        %% MAX-FLOW Algorithm
        if strcmp(segmentationAlgorithm, 'maxFlow_JingYuan')

            % rather than segmenting the input bitmap, segment vesselnessStack and overlay on the input
            useTubularityAsImage = true; 

            % http://www.mathworks.com/matlabcentral/fileexchange/34126-fast-continuous-max-flow-algorithm-to-2d-3d-image-segmentation
            visualizeOn = false; saveOn = false;
            [rows, cols, slices] = size(imageStack);
            parameters = [rows; cols; slices; 200; 5e-4; 0.35; 0.11];
                %                para 0,1,2 - rows, cols, heights of the given image
                %                para 3 - the maximum number of iterations
                %                para 4 - the error bound for convergence
                %                para 5 - cc for the step-size of augmented Lagrangian method
                %                para 6 - the step-size for the graident-projection of p

            ulab = [0.001 0.4]; % [source sink] empirically set, update for more adaptive later                
            [uu, weighed, uu_binary] = segment_maxFlow_wrapper(imageStack, vesselnessStack, parameters, ulab, visualizeOn, saveOn, useTubularityAsImage, options);
            segmentationStack = weighed;
            mask = uu_binary;

        %% ASETS : Matlab Level Sets
        elseif strcmp(segmentationAlgorithm, 'asets_levelSets')

            % https://github.com/ASETS/asetsMatlabLevelSets
            % by Martin Rajchl (@mrajchl), Imperial College London (UK)
            disp('Segmentation with ASETS: Level Sets'); disp(' ')
            
            % Pre-process images  
            [imageStack, fusionImageStack, fusionImageStackBright, vesselnessStack, edges, edgesSigmoid] = segment_asetsPreProcessImages(imageStack, vesselnessStack);
            
            % init region
            regionInit = segment_createRegionFromVessel(vesselnessStack);

            % Settings
            fileOutBase = 'iter3D_';
            visualize3D = true; 
            visualizeON = true;
            sliceIndex = 1;

            % Parameters
            maxLevelSetIterations = 2; % number of maximum time steps
            tau = 500; % speed parameter
            w1 = 0.35; % weight parameter for intensity data term
            w2 = 0.25; % weight parameter for the speed data term
            w3 = 0.4; % weight parameter for the vesselnessStackness

            % Set up the parameters for the max flow optimizer:
            % [1] graph dimension 1
            % [2] graph dimension 2
            % [3] number of maximum iterations for the optimizer (default 200)
            % [4] an error bound at which we consider the solver converged (default
            %     1e-5)
            % [5] c parameter of the multiplier (default 0.2)
            % [6] step 7size for the gradient descent step when calulating the spatial
            %     flows p(x) (default 0.16)        
            [sx, sy, sz] = size(imageStack);
            maxIter = 500;
            errorBound = 1e-6;
            cMultiplier = 0.2;
            stepSize = 0.16;
            pars = [sx; sy; sz; maxIter; errorBound; cMultiplier; stepSize];

            % for creating alpha from the edges (regularization term)
            regWeight1 = 0.005; regWeight2 = 0.01; regWeight3 = 5;

            % Actual call 
            secondPass = false;
            imgForSegmentation = fusionImageStackBright;
            mask = asets_demoWrapper_3D_v3(imgForSegmentation, vesselnessStack, edges, regionInit, ...
                                             maxLevelSetIterations, tau, w1, w2, w3, pars, ...
                                             regWeight1, regWeight2, regWeight3, ...
                                             secondPass, sliceIndex, visualize3D, visualizeON, fileOutBase);

            % weigh the input with binary region mask
            segmentationStack = mask .* imageStack;
            
        % Add Something
        elseif strcmp(segmentationAlgorithm ,'goodSegmentationAlgorithm')
        
        else

        end
          
    %% OUTPUT
    
        save(fullfile(options.pathBigFiles, [options.segmImageOutBase, '_regionMaskOnly.mat']), 'mask')
    
        disp(' ')
        disp(['SEGMENTATION DONE (timePoint = ', num2str(t), ')'])
        disp(' ')