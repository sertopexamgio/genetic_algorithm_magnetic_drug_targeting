function [  ] = saveComsolModel( model, path, number_of_magnets )


% the model with the best magnet configuration will be stored in this path
result_path = strcat( path, '\Results' );

% extract the current time in the following format
formatOut = 'dd-mmm-yyyy_HH-MM-SS';
date_time = datestr( datetime, formatOut );

% set the name of the model
if number_of_magnets == 1
    model_name = strcat( ['Optimization result for 1 magnet ', date_time] );
else
    model_name = strcat( strcat( ['Optimization result for ', int2str( number_of_magnets )] ), strcat( [' magnets ', date_time] ) );
end

% save the model
model_path = strcat( result_path, '\', model_name );
model.save( model_path );

% display the path
if number_of_magnets == 1
    fprintf( 'The optimized model with 1 magnet has been saved under the following path:\n' );
else
    fprintf( 'The optimized model with %i magnets has been saved under the following path:\n', number_of_magnets );
end
disp( result_path );

end

