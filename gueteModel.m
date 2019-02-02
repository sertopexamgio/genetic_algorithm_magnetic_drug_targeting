%% Optimization Model for drug targeting
%%% In this Project, magnet parameters will be optimized in order to 
%%% maximize the average mean magnetic flux density in a tumor model.
%author Serxhio Rira
%version v.0.1 
%date 24.05.2017


clear
clc

fprintf('\nCreate a Comsol model\n');
model = modelBuilder;

obj_func = @(variables) runComsol(model, variables);
fprintf('\nObject function to maximize has been created\n');

fprintf('\nStart optimization with a generic algorithm\n');

population_size = 3;
maximum_generation_size = 10;
maximum_generations = 50;
reproduction_prob = 0.3;
recombination_prob = 0.3;
mutation_prob = 0.3;
immigration_prob = 0.1;
num_of_variables = 4;
low_boundary = 1;
high_boundary = 6;
optimum_solution = -0.3;
[population, iterations, solution] = ga_optimization(obj_func,population_size,maximum_generation_size,maximum_generations,reproduction_prob,recombination_prob,mutation_prob, immigration_prob,num_of_variables,low_boundary, high_boundary,optimum_solution);


