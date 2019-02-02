function out = runComsol( model, number_of_variables_per_magnet, variables )

% This function runs the simulation of the given model in Comsol and
% returns the average mean magnetic flux density in the constructed
% tumor domain.


% nonzeros() returns a full column vector of the nonzero elements
% floor() gives the integer part of the division
num_of_magnets = floor( size(nonzeros( variables(1,:) ), 1)/number_of_variables_per_magnet );

% set the given parameters to the model
variable_index = 1;
for index_of_magnet = 1:num_of_magnets
    if or( variables( 1, variable_index ) == 0, variables( 1, variable_index + 1 ) == 0)
        % Comsol should not scale with a variable equal to zero
        disp( 'ERROR: The variable value cannot be zero' );
    else
        % set the height Hi of the magnet i
        model.param.set( strcat('H', int2str(index_of_magnet)), num2str( round(variables(1,variable_index), 2) ) );
        % set the radius Ri of the magnet i
        model.param.set( strcat('R', int2str(index_of_magnet)), num2str( round(variables(1,variable_index+1), 2) ) );
    end
    variable_index = variable_index + number_of_variables_per_magnet;
end

% run the simulation
model.sol('sol1').runAll;

% store the solution
model.result.numerical('av1').setResult;

% return the mean magnetic flux density
out = model.result.table('tbl1').getReal();
