function out = buildComsolModel( optimization_path, num_of_magnets )

if nargin == 0
    % none argument has been given
    disp('Please give the number of magnets as an argument to this function');
    out = 0;
else
    
    % import important comsol libraries
    import com.comsol.model.*
    import com.comsol.model.util.*
    
    %% MODEL COMPONENTS
    
    disp('Create model components...');
    % create a comsol model
    model = ModelUtil.create('Model');
    model.modelPath( [optimization_path] );
    model.comments('Optimazing_Magnet_Arrays_for_Drug_Targeting\n\n');
    model.comments('In this Project, magnet parameters will be optimized in order to maximize the average mean magnetic flux density in a tumor model.');
    model.author('Serxhio Rira');
    model.label('Optimization_Drug_Targeting.mph');
    
    % create model components
    model.modelNode.create('comp1');
    model.geom.create('geom1', 3);
    % set the length unit to millimeter
    model.geom('geom1').lengthUnit('mm');
    % create the mesh component
    model.mesh.create('mesh1', 'geom1');
    model.physics.create('mf', 'InductionCurrents', 'geom1');
    model.study.create('std1');
    % set the study to stationary
    model.study('std1').create('stat', 'Stationary');
    model.study('std1').feature('stat').activate('mf', true);
    
    
    %% DEFINITIONS
    
    % Set global parameters
    disp('Set global parameters...');
    % set the radius of the tumor
    model.param.set('R_tumor', '3.828186472892078 [mm]');
    model.param.descr('R_tumor', 'Radius of tumor');
    % set the number of magnets
    model.param.set('NumOfMag', int2str(num_of_magnets) );
    model.param.descr('NumOfMag', 'Number of magnets');
    
    % set the initial varibles of the magnets
    for i = 1:num_of_magnets
        % set the height of each magnet
        model.param.set( strcat('H', int2str(i)), '1' );
        model.param.descr( strcat('H', int2str(i)), strcat( 'Height of magnet ', int2str(i)) );
        % set the radius of each magnet
        model.param.set( strcat('R', int2str(i)), '1');
        model.param.descr( strcat('R', int2str(i)), strcat( 'Radius of magnet ', int2str(i)) );
        % set the magnetic remanenz of each magnet
        model.param.set( strcat('Bz', int2str(i)), '1.3' );
        model.param.descr( strcat('Bz', int2str(i)), strcat( 'Remanenz of magnet ', int2str(i)) );
    end
    
    %% GEOMETRY
    
    % Import Air space
    disp('Create air space geometry...');
    model.geom('geom1').create('space', 'Import');
    % path of the air space
    air_space_filename = strcat(optimization_path, '\Comsol_Imports\air.mphbin');
    model.geom('geom1').feature('space').set('filename', [air_space_filename]);
    model.geom('geom1').feature.move('space', 0);
    model.geom('geom1').feature('space').label('Air space');
    model.geom('geom1').feature('space').importData;
    model.geom('geom1').run('space');
    
    % Import Tumor model
    disp('Create tumor geometry...');
    model.geom('geom1').create('tumor', 'Import');
    model.geom('geom1').feature('tumor').label('Tumor');
    % path of the tumor model
    tumor_filename = strcat(optimization_path, '\Comsol_Imports\tumor_V=235.mphbin');
    model.geom('geom1').feature('tumor').set( 'filename', tumor_filename );
    model.geom('geom1').feature('tumor').importData;
    model.geom('geom1').run('tumor');
    
    magnet_filename = strcat(optimization_path, '\Comsol_Imports\magnet1x1.mphbin');
    for i = 1:num_of_magnets
        disp( strcat(['Create geometry of magnet ', int2str(i), '...']) );
        % Import a magnet
        import_name = strcat('magnet', int2str(i));
        model.geom('geom1').create(import_name, 'Import');
        model.geom('geom1').feature( import_name ).set( 'filename', [magnet_filename] );
        model.geom('geom1').feature( import_name ).importData;
        model.geom('geom1').run( import_name );
        % Scale the magnet
        scale_name = strcat('sca', int2str(i));
        model.geom('geom1').create( scale_name, 'Scale' );
        model.geom('geom1').feature( scale_name ).selection('input').set( {import_name} );
        model.geom('geom1').feature( scale_name ).set('type', 'anisotropic');
        scale_xy = strcat( 'R', int2str(i) );
        scale_z = strcat( 'H', int2str(i) );
        model.geom('geom1').feature( scale_name ).set( 'anisotropic', {scale_xy scale_xy scale_z} );
        model.geom('geom1').run( scale_name );
        % Move the magnet
        move_name = strcat('mov', int2str(i));
        model.geom('geom1').create( move_name, 'Move' );
        model.geom('geom1').feature( move_name ).selection('input').set( { scale_name } );
        dz = '-R_tumor';
        k = i;
        while k > 1
            dz = strcat( dz, strcat( '-H', int2str(k-1) ) );
            k =k-1;
        end
        model.geom('geom1').feature( move_name ).set( 'displz', dz );
        model.geom('geom1').run( move_name );
    end
    
    % Run the geometry
    model.geom('geom1').run;
    disp('Geometry is ready!');
    
    
    %% EXPLICITS
    disp('Create explicits...');
    model.selection.create('sel1', 'Explicit');
    model.selection('sel1').label('Tumor');
    model.selection('sel1').set([2]);
    model.selection.create('sel2', 'Explicit');
    model.selection('sel2').label('Magnets');
    domain = [];
    for i = 1:num_of_magnets
        domain = [ domain, (i+2) ];
    end
    model.selection('sel2').set( domain );
    model.selection.create('sel3', 'Explicit');
    model.selection('sel3').label('Air Space');
    model.selection('sel3').set([1]);
    
    
    %% MATERIALS
    
    % Create material for tumor
    disp('Create tumor material...');
    model.material.create( 'mat1', 'Common', 'comp1');
    model.material('mat1').selection.set( model.selection('sel1').entities(model.selection('sel1').dimension) );
    model.material('mat1').label('Tumor');
    % Set properties of tumor material
    model.material('mat1').propertyGroup('def').set('heatcapacity', '3421[J/(kg*K)]');
    model.material('mat1').propertyGroup('def').set('density', '1090[kg/m^3]');
    model.material('mat1').propertyGroup('def').set('thermalconductivity', {'0.49[W/(m*K)]' '0' '0' '0' '0.49[W/(m*K)]' '0' '0' '0' '0.49[W/(m*K)]'});
    model.material('mat1').propertyGroup('def').set('electricconductivity', {'0'});
    model.material('mat1').propertyGroup('def').set('relpermeability', {'1'});
    model.material('mat1').propertyGroup('def').set('relpermittivity', {'1'});
    model.material('mat1').set('family', 'plastic');
    % Create material for magnets
    disp('Create magnet material...');
    model.material.create('mat2', 'Common', 'comp1');
    model.material('mat2').selection.set( model.selection('sel2').entities(model.selection('sel2').dimension) );
    model.material('mat2').label('Magnet');
    % Set properties of magnet material
    model.material('mat2').propertyGroup('def').set('relpermeability', {'1.05'});
    model.material('mat2').propertyGroup('def').set('electricconductivity', {'700000'});
    model.material('mat2').propertyGroup('def').set('relpermittivity', {'1'});
    
    % Create material for air space
    disp('Create air material...');
    model.material.create('mat3', 'Common', 'comp1');
    model.material('mat3').selection.set( model.selection('sel3').entities(model.selection('sel3').dimension) );
    model.material('mat3').label('Air');
    model.material('mat3').set('family', 'air');
    % Set properties of air
    model.material('mat3').propertyGroup('def').set('relpermeability', '1');
    model.material('mat3').propertyGroup('def').set('relpermittivity', '1');
    model.material('mat3').propertyGroup('def').set('dynamicviscosity', 'eta(T[1/K])[Pa*s]');
    model.material('mat3').propertyGroup('def').set('ratioofspecificheat', '1.4');
    model.material('mat3').propertyGroup('def').set('electricconductivity', '0[S/m]');
    model.material('mat3').propertyGroup('def').set('heatcapacity', 'Cp(T[1/K])[J/(kg*K)]');
    model.material('mat3').propertyGroup('def').set('density', 'rho(pA[1/Pa],T[1/K])[kg/m^3]');
    model.material('mat3').propertyGroup('def').set('thermalconductivity', 'k(T[1/K])[W/(m*K)]');
    model.material('mat3').propertyGroup('def').set('soundspeed', 'cs(T[1/K])[m/s]');
    model.material('mat3').propertyGroup('def').func.create('eta', 'Piecewise');
    model.material('mat3').propertyGroup('def').func('eta').set('funcname', 'eta');
    model.material('mat3').propertyGroup('def').func('eta').set('arg', 'T');
    model.material('mat3').propertyGroup('def').func('eta').set('extrap', 'constant');
    model.material('mat3').propertyGroup('def').func('eta').set('pieces', {'200.0' '1600.0' '-8.38278E-7+8.35717342E-8*T^1-7.69429583E-11*T^2+4.6437266E-14*T^3-1.06585607E-17*T^4'});
    model.material('mat3').propertyGroup('def').func.create('Cp', 'Piecewise');
    model.material('mat3').propertyGroup('def').func('Cp').set('funcname', 'Cp');
    model.material('mat3').propertyGroup('def').func('Cp').set('arg', 'T');
    model.material('mat3').propertyGroup('def').func('Cp').set('extrap', 'constant');
    model.material('mat3').propertyGroup('def').func('Cp').set('pieces', {'200.0' '1600.0' '1047.63657-0.372589265*T^1+9.45304214E-4*T^2-6.02409443E-7*T^3+1.2858961E-10*T^4'});
    model.material('mat3').propertyGroup('def').func.create('rho', 'Analytic');
    model.material('mat3').propertyGroup('def').func('rho').set('funcname', 'rho');
    model.material('mat3').propertyGroup('def').func('rho').set('args', {'pA' 'T'});
    model.material('mat3').propertyGroup('def').func('rho').set('expr', 'pA*0.02897/8.314/T');
    model.material('mat3').propertyGroup('def').func('rho').set('dermethod', 'manual');
    model.material('mat3').propertyGroup('def').func('rho').set('argders', {'pA' 'd(pA*0.02897/8.314/T,pA)'; 'T' 'd(pA*0.02897/8.314/T,T)'});
    model.material('mat3').propertyGroup('def').func.create('k', 'Piecewise');
    model.material('mat3').propertyGroup('def').func('k').set('funcname', 'k');
    model.material('mat3').propertyGroup('def').func('k').set('arg', 'T');
    model.material('mat3').propertyGroup('def').func('k').set('extrap', 'constant');
    model.material('mat3').propertyGroup('def').func('k').set('pieces', {'200.0' '1600.0' '-0.00227583562+1.15480022E-4*T^1-7.90252856E-8*T^2+4.11702505E-11*T^3-7.43864331E-15*T^4'});
    model.material('mat3').propertyGroup('def').func.create('cs', 'Analytic');
    model.material('mat3').propertyGroup('def').func('cs').set('funcname', 'cs');
    model.material('mat3').propertyGroup('def').func('cs').set('args', {'T'});
    model.material('mat3').propertyGroup('def').func('cs').set('expr', 'sqrt(1.4*287*T)');
    model.material('mat3').propertyGroup('def').func('cs').set('dermethod', 'manual');
    model.material('mat3').propertyGroup('def').func('cs').set('argders', {'T' 'd(sqrt(1.4*287*T),T)'});
    model.material('mat3').propertyGroup('def').addInput('temperature');
    model.material('mat3').propertyGroup('def').addInput('pressure');
    model.material('mat3').propertyGroup.create('RefractiveIndex', 'Refractive index');
    model.material('mat3').propertyGroup('RefractiveIndex').set('n', '1');
    
    disp('Materials are ready!');
    
    %% MAGNETIC FIELDS
    disp('Apply magnetic laws...');
    % Set physical properties to the model
    for i = 1:num_of_magnets
        feature_name =  strcat('al', int2str(i+1));
        model.physics('mf').create( feature_name, 'AmperesLaw', 3 );
        % +2 because the first two are the air space and the tumor region
        model.physics('mf').feature( feature_name ).selection.set( [(i+2)] );
        model.physics('mf').feature( feature_name ).set('ConstitutiveRelationH', 'RemanentFluxDensity');
        Bz = strcat('Bz', int2str(i));
        model.physics('mf').feature( feature_name ).set('Br', {'0' '0' Bz});
    end
    
    %% MESH
    % Run the mesh
    disp('Meshing is ready!');
    % the index 4 correspondes to 'Fine' meshing
    model.mesh('mesh1').autoMeshSize(4);
    model.mesh('mesh1').run;
    
    
    %% STUDY
    model.sol.create('sol1');
    model.sol('sol1').study('std1');
    
    model.study('std1').feature('stat').set('notlistsolnum', 1);
    model.study('std1').feature('stat').set('notsolnum', '1');
    model.study('std1').feature('stat').set('listsolnum', 1);
    model.study('std1').feature('stat').set('solnum', '1');
    
    model.sol('sol1').create('st1', 'StudyStep');
    model.sol('sol1').feature('st1').set('study', 'std1');
    model.sol('sol1').feature('st1').set('studystep', 'stat');
    model.sol('sol1').create('v1', 'Variables');
    model.sol('sol1').feature('v1').set('control', 'stat');
    model.sol('sol1').create('s1', 'Stationary');
    model.sol('sol1').feature('s1').create('fc1', 'FullyCoupled');
    model.sol('sol1').feature('s1').create('i1', 'Iterative');
    model.sol('sol1').feature('s1').feature('i1').set('linsolver', 'fgmres');
    model.sol('sol1').feature('s1').feature('i1').create('mg1', 'Multigrid');
    model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('pr').create('so1', 'SOR');
    model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('po').create('so1', 'SOR');
    model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').create('ams1', 'AMS');
    model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').feature('ams1').set('prefun', 'ams');
    model.sol('sol1').feature('s1').feature('i1').feature('mg1').feature('cs').feature('ams1').set('sorvecdof', {'comp1_A'});
    model.sol('sol1').feature('s1').feature('fc1').set('linsolver', 'i1');
    model.sol('sol1').feature('s1').feature.remove('fcDef');
    model.sol('sol1').attach('std1');
    
    model.result.create('pg1', 'PlotGroup3D');
    model.result('pg1').label('Magnetic Flux Density Norm (mf)');
    model.result('pg1').set('data', 'dset1');
    model.result('pg1').feature.create('mslc1', 'Multislice');
    model.result('pg1').feature('mslc1').set('data', 'parent');
    
    model.result('pg1').feature('mslc1').set('rangecoloractive', 'on');
    model.result('pg1').feature('mslc1').set('rangecolormin', '0');
    model.result('pg1').feature('mslc1').set('rangecolormax', '0.4');
    model.result('pg1').feature('mslc1').set('colortablerev', 'off');
    
    model.result.dataset('dset1').selection.geom('geom1', 3);
    model.result.dataset('dset1').selection.geom('geom1', 3);
    model.result.dataset('dset1').selection.set([2]);
    
    model.result.numerical.create('av1', 'AvVolume');
    model.result.numerical('av1').selection.set([2]);
    model.result.table.create('tbl1', 'Table');
    model.result.table('tbl1').comments('Volume Average 1 ()');
    model.result.numerical('av1').set('table', 'tbl1');
    model.result.numerical('av1').set('expr', {'mf.normB'});
    model.result.numerical('av1').set('descr', {'Magnetic flux density norm'});
    model.result.numerical('av1').set('unit', {'T'});
    model.result.numerical('av1').set('table', 'tbl1');
    
    %% VIEW
    model.view('view1').set('scenelight', 'on');
    model.view('view1').hideObjects.create('hide1');
    model.view('view1').hideObjects('hide1').init;
    model.view('view1').hideObjects('hide1').add({'space'});
    model.view('view1').label('Tumor and Magnets');
    
    
    %% RETURN
    fprintf('Comsol model is ready!\n\n');
    out = model;
    
end



