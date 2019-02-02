function [ optimal_magnet_configurations, optimal_iterations, optimal_magnetic_fields ] = optimization( number_of_magnets, number_of_best_configurations, maximum_number_of_configurations, maximum_iterations, reproduction_probability, recombination_probability, mutation_probability, immigration_probability, number_of_variables_per_magnet, low_boundaries, high_boundaries, stop_criterium )

% Optimization Model for drug targeting systems
%
% In this Project, magnet parameters will be optimized in order to
% maximize the average mean magnetic flux density in a tumor model.
% The user can set the number of magnets and by using a genetic algorithm,
% the magnetic configurations with the highest magnetic flux densities will
% be extracted. We use by default two variables, the height and the width
% of a magnet. This can also work for much more variables. The user must
% give the numbers of magnet, that should be optimized.
%
% author Serxhio Rira
% version v.1.2
% date 26.07.2017


%% initialize the Livelink connection ( Comsol - Matlab )

% Firstly we need to set up the Matlab-Livelink connection with a Comsol
% server.
optimization_path = initializeLivelink;


%% set default values if not given from the user

% nargin is the number of arguments given in this function
if nargin < 12
    % if we reach this value (in Tesla), then we are satisfied enough to
    % stop the optimization
    stop_criterium = 0.3;
end
if nargin < 11
    % this is the highest values that the parameters should take
    % this variable can also be implemented as an array with different
    % values
    high_boundaries = 6;
end
if nargin < 10
    % this is the lowest values that the parameters should take
    % this variable can also be implemented as an array with different
    % values
    low_boundaries = 1;
end
if nargin < 9
    % we will optimize two parameters for each magnet, the height and the width
    number_of_variables_per_magnet = 2;
end
if nargin < 8
    % this variable describes how often will the immigration technique take
    % place
    immigration_probability = 0.2;
end
if nargin < 7
    % this variable describes how often will the mutation technique take
    % place
    mutation_probability = 0.3;
end
if nargin < 6
    % this variable describes how often will the recombination technique take
    % place
    recombination_probability = 0.3;
end
if nargin < 5
    % this variable describes how often will the reproduction technique take
    % place
    reproduction_probability = 0.2;
end
if nargin < 4
    % this variable describes the maximum number of iterations
    maximum_iterations = 2;
end
if nargin < 3
    % this variable describes the number of maximum magnet configurations(
    % individuums) per iteration(generation)
    maximum_number_of_configurations = 20;
end
if nargin < 2
    % this variable describes the number of the best magnet configurations
    % (individuums) that survived after each iteration ( generation )
    number_of_best_configurations = 10;
end

% allocate memory for the solutions
optimal_magnet_configurations = [];
optimal_iterations = [];
optimal_magnetic_fields = [];

% there will be an optimization for each given number of magnets
number_of_optimizations = size( number_of_magnets, 2 );


%% Start the optimization for each given number of magnets

for i = 1:number_of_optimizations
    
    % start new optimization with a given number of magnets
    current_number_of_magnets = number_of_magnets( 1, i );
    
    if current_number_of_magnets == 1
        fprintf( '\n\n******************** Starting optimization for 1 magnet!!! ********************\n\n' );
    else
        fprintf( '\n\n******************** Starting optimization for %i magnets!!! ********************\n\n', current_number_of_magnets );
    end
    
    % check if the given number of magnets is valid
    if current_number_of_magnets <= 0
        disp( 'ERROR: The number of magnets should be positive!' );
        return;
    end
    
    if current_number_of_magnets == 1
        fprintf( '\nCreate the initial Comsol model with 1 magnet\n' );
    else
        fprintf( '\nCreate the initial Comsol model with %i magnets\n', current_number_of_magnets );
    end
    
    % create the initial Comsol model, that will be later optimized
    model = buildComsolModel( optimization_path, current_number_of_magnets );
    
    % set the objective function that should be maximized
    obj_func = @(variables) runComsol( model, number_of_variables_per_magnet, variables );
    
    % this variable describes the total number of parameters that
    % should be optimized
    total_number_of_parameters = number_of_variables_per_magnet * current_number_of_magnets;
    
    if current_number_of_magnets == 1
        fprintf( '\nStart the generic algorithm for 1 magnet\n' );
    else
        fprintf( '\nStart the generic algorithm for %i magnets\n', current_number_of_magnets );
    end
    
    % start the genetic algorithm
    [ new_magnet_configurations, new_iterations, new_magnetic_fields ] = geneticAlgorithm(obj_func, number_of_best_configurations, maximum_number_of_configurations, maximum_iterations, reproduction_probability, recombination_probability, mutation_probability, immigration_probability, total_number_of_parameters, low_boundaries, high_boundaries, stop_criterium);
    fprintf('\nGeneric algorithm completed successfully!\n');
    
    % if this is not the first optimization
    if i ~= 1
        new_size = size( new_magnet_configurations, 2 );
        old_size = size( optimal_magnet_configurations, 2 );
        % resize the size of the number of magnet configurations (populations)
        % by adding zeros in order to fit the new populations of the current optimization
        if new_size > old_size
            optimal_magnet_configurations = padarray( optimal_magnet_configurations, [0,(new_size - old_size)], 'post');
        else
            new_magnet_configurations = padarray( new_magnet_configurations, [0,(old_size - new_size)], 'post');
        end
    end
    
    % Push back the new optimization results
    optimal_magnet_configurations = [ optimal_magnet_configurations; new_magnet_configurations ];
    optimal_iterations = [ optimal_iterations; new_iterations ];
    optimal_magnetic_fields = [ optimal_magnetic_fields; new_magnetic_fields ];
    
    % if this is not the first optimization
    if i ~= 1
        % Sort the solutions in descending order(the best on the top)
        % use 'ascend' for minimization problems and 'descend' for maximization
        % problems
        [ optimal_magnetic_fields, sorting_order ]=sort( optimal_magnetic_fields, 1, 'descend');
        % keep only the best magnet configurations for the next generation
        optimal_magnetic_fields = optimal_magnetic_fields( 1:number_of_best_configurations, : );
        optimal_magnet_configurations = optimal_magnet_configurations( sorting_order, : );
        optimal_magnet_configurations = optimal_magnet_configurations( 1:number_of_best_configurations, :);
    end
    
    
end


%% save the model with the best magnet configuration of all optimizations

% run the model with the optimal solution
runComsol( model, number_of_variables_per_magnet, optimal_magnet_configurations(1,:) );

% find the optimal number of magnets, that has shown the highest magnetic
% flux dencities
optimal_number_of_magnets = floor( size( nonzeros( optimal_magnet_configurations(1,:) ), 1)/number_of_variables_per_magnet);

% save this model
saveComsolModel( model, optimization_path, optimal_number_of_magnets);


%% Optimization completed successfully
fprintf('\nOptimization completed successfully!\n');

