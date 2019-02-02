function [ best_population, iterations, best_value ] = geneticAlgorithm( comsol, number_of_best_configurations, maximum_number_of_configurations, maximum_iterations, reproduction_probability, recombination_probability, mutation_probability, immigration_probability, total_number_of_parameters, low_boundaries, high_boundaries, stop_criterium )

% A genetic algorithm is a search heuristic that mimics the process of
% natural evolution. It is used to generate useful solutions to
% optimization and search problems. Genetic algorithms belong to the larger
% class of evolutionary algorithms, which generate solutions to
% optimization problems using techniques inspired by natural evolution,
% such as inheritance, mutation, selection, and crossover.
%
% Output variables:
% - best_configuration: it's the optimum input of the objective function
% - iterations: it's total number of iterations
% - best_value: it's the optimum output value of the objective function
%
% Input variables:
% - comsol: it's the handle of the objective function to minimize (example: comsol=@(x) runComsol(x) where x is the variables vector)
% - number_of_best_configurations: Number of individuals (number of initial points)
% - maximum_number_of_configurations: this variable describes the number of maximum magnet configurations(individuums) per iteration(generation)
% - maximum_iterations: Max number of generations (number of max iterations)
% - reproduction_probability: % this variable describes how often will the reproduction technique take place
% - recombination_probability: % this variable describes how often will the recombination technique take place
% - mutation_probability: % this variable describes how often will the mutation technique take place
% - immigration_probability: this variable describes how often will the immigration technique take place
% - total_number_of_parameters: this is the number of the objective function variables
% - low_boundaries: this is the lowest values that the parameters should take
% - high_boundaries: this is the highest values that the parameters should take
% - stop_criterium: if we reach this value (in Tesla), then we are satisfied enough to stop the optimization

% number of generations
iterations = 0;

% initial stop criterium
% we subtract one, just to pass the condition the first time
stop = stop_criterium - 1;

% The sum of the probabilities of the mutation operations must be 1.
%Reproduction probability
fprintf( 'Reproduction probability: %d%% \n', reproduction_probability*100 );
%Recombination probability
fprintf( 'Recombination probability: %d%% \n', recombination_probability*100);
%Mutation probability
fprintf( 'Mutation probability: %d%% \n', mutation_probability*100 );
%Immigration probability
fprintf( 'Immigration probability: %d%% \n', immigration_probability*100 );

%% Calculate the initial configurations

% initilize a random configuration
configuration = low_boundaries + ( high_boundaries - low_boundaries ) .* rand( number_of_best_configurations, total_number_of_parameters );
fprintf('Calculation of the magnetic flux densities of %d configurations...\n', number_of_best_configurations);
for l = 1:number_of_best_configurations
    magnetic_flux(l,1) = comsol( configuration(l,:) );
end
fprintf('Calcultion completed!\n');

% Sort the population in descending order
% use 'ascend' for minimization problems and 'descend' for maximization
% problems
[ sorted_magnetic_flux, sorting_order ] = sort( magnetic_flux, 1, 'descend' );
sorted_configurations = configuration( sorting_order, : );
disp('Initial random configurations:');
disp(sorted_configurations);
disp('Mean magnetic flux density [T] in the tumor volume for each magnet configuration:');
disp(sorted_magnetic_flux);


%% Evolution

fprintf('Start evolution...\n\n');

while( iterations<maximum_iterations && stop<stop_criterium )
    
    iterations = iterations + 1;
    fprintf('Iteration: %d \n\n', iterations);
    
    % calculate population ranking
    sum_mag_flux = 0;
    for l=1:number_of_best_configurations
        sum_mag_flux = sum_mag_flux + (sorted_magnetic_flux(l,1))^-1;
    end
    for l=1:number_of_best_configurations
        rank(l,1)=(sorted_magnetic_flux(l,1))^-1/sum_mag_flux;
    end
    
    number_of_new_configurations = 0;
    new_configurations = [];
    while( (number_of_new_configurations + number_of_best_configurations) < maximum_number_of_configurations )
        % get a random probability value
        random_probability =rand();
        if random_probability>=0 && random_probability<reproduction_probability
            %% Reproduction
            % Choose the parents with the wheel of fortune
            disp( 'Reproduction...' );
            gen=rand();
            k=1;
            r=0;
            while(1)
                r=r+rank(k,1);
                if gen<=r;
                    break
                else
                    k=k+1;
                end
            end
            disp('New configuration through reproduction:');
            number_of_new_configurations = number_of_new_configurations + 1;
            new_configurations( number_of_new_configurations, : ) = sorted_configurations( k, : );
            disp( sorted_configurations( k, : ) );
            
        else if random_probability>=reproduction_probability && random_probability<(recombination_probability+reproduction_probability)
                %% Recombination
                disp( 'Recombination...'  );
                % Set the initial minimum and maximum values
                % in such a way that it can pass in the loop the first time
                minimum = low_boundaries - 1;
                maximum = high_boundaries + 1;
                % loop until the minimum and maximum values of the sons are valid
                while(minimum<low_boundaries || maximum>high_boundaries)
                    for h=1:2
                        gen=rand();
                        k=1;
                        r=0;
                        while(1)
                            r=r+rank(k,1);
                            if gen<=r;
                                break
                            else
                                k=k+1;
                            end
                        end
                        % index of parents
                        recomb(h,1)=k;
                        %TODO: they should not have the same parents
                    end
                    % The alpha coefficient with a gaussian distribution with average = 0.8 and sigma = 0.5
                    alpha = normrnd( 0.8, 0.5 );
                    new_configuration(1,:)=alpha.*sorted_configurations( recomb(1,1), : ) + (1-alpha).*sorted_configurations( recomb(2,1), : );
                    new_configuration(2,:)=alpha.*sorted_configurations( recomb(2,1), : ) + (1-alpha).*sorted_configurations( recomb(1,1), : );
                    minimum=min(min(new_configuration(1,:)),min(new_configuration(2,:)));
                    maximum=max(max(new_configuration(1,:)),max(new_configuration(2,:)));
                end
                number_of_new_configurations = number_of_new_configurations + 2;
                new_configurations(number_of_new_configurations - 1, :) = new_configuration(1,:);
                new_configurations(number_of_new_configurations, :) = new_configuration(2,:);
                disp('New configurations through recombination:');
                disp( new_configuration );
                
            else if random_probability>=(recombination_probability+reproduction_probability) && random_probability<(recombination_probability+reproduction_probability+mutation_probability)
                    %% Mutation
                    disp( 'Mutation...' );
                    minimum = low_boundaries - 1;
                    maximum = high_boundaries + 1;
                    while(minimum<low_boundaries || maximum>high_boundaries)
                        gen=rand();
                        k=1;
                        r=0;
                        while(1)
                            r=r+rank(k,1);
                            if gen<=r;
                                break
                            else
                                k=k+1;
                            end
                        end
                        % Add to genotype random values created by considering a Gaussian distribution
                        % with zero mean and variance 0.8
                        new_configuration = sorted_configurations(k,:) + normrnd(0,0.8,1,total_number_of_parameters);
                        minimum=min(new_configuration);
                        maximum=max(new_configuration);
                    end
                    number_of_new_configurations = number_of_new_configurations + 1;
                    new_configurations( number_of_new_configurations, : ) = new_configuration( 1, : );
                    disp('New configuration through mutation:');
                    disp( new_configuration( 1, : ) );
                else if ( ( random_probability>=(recombination_probability+reproduction_probability+mutation_probability) ) && ( random_probability<(recombination_probability+reproduction_probability+mutation_probability+immigration_probability) ) && ( maximum_number_of_configurations>( size(sorted_configurations,1) + number_of_new_configurations ) ) )
                        %% Immigration
                        disp('Immigration...');
                        num_imm_ind =  maximum_number_of_configurations - size( sorted_configurations,1) - number_of_new_configurations;
                        fprintf('%i new configurations through immigration\n', num_imm_ind);
                        for l=1:num_imm_ind
                            number_of_new_configurations = number_of_new_configurations + 1;
                            % generate random numbers in the interval
                            % (low_boundaries, high_boundaries)
                            new_configurations( number_of_new_configurations, : ) = low_boundaries + (high_boundaries-low_boundaries) .* rand( 1, total_number_of_parameters );
                            disp( new_configurations( number_of_new_configurations, : ) );
                        end
                    end
                end
            end
        end
    end
    % calculation of the best individuals that will be part of the new population
    fprintf( '%d new configurations created in the current iteration\n', size( new_configurations, 1 ) );
    disp( 'Calculation of their magnetic flux densities...' );
    new_magnetic_flux = [];
    for l=1:size( new_configurations, 1 )
        new_magnetic_flux( l, 1 ) = comsol( new_configurations( l, : ) );
    end
    fprintf('Calculation completed!\n\n');
    
    total_configurations = [ sorted_configurations; new_configurations ];
    disp( 'All configurations from the current iteration:' );
    disp( total_configurations );
    total_magnetic_flux = [ sorted_magnetic_flux; new_magnetic_flux ];
    disp( 'All the corresponding mean magnetic flux densities [T] from the current iteration:' );
    disp( total_magnetic_flux );
    
    % Sort vector in descending order
    % use 'ascend' for minimization problems and 'descend' for maximization
    % problems
    [ total_sorted_magnetic_flux, sorting_order ] = sort( total_magnetic_flux, 1, 'descend' );
    sorted_magnetic_flux = total_sorted_magnetic_flux( 1:number_of_best_configurations, : );
    total_sorted_configurations = total_configurations( sorting_order, : );
    sorted_configurations = total_sorted_configurations( 1:number_of_best_configurations, : );
    
    disp( 'Best configurations survived for the next iteration:' );
    disp( sorted_configurations );
    disp( 'Magnetic flux densities from the survived configurations:' );
    disp( sorted_magnetic_flux );
    
    %stop=abs(f(1)-f(numInd));
    stop = total_sorted_magnetic_flux( 1 );
end

best_value = total_sorted_magnetic_flux( 1:number_of_best_configurations, : );
best_population = sorted_configurations;