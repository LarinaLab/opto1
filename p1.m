close all force; clear; clc;
%%
import zaber.motion.ascii.Connection;
import zaber.motion.Units;
import zaber.motion.Library;
%%

%connect to device
Library.enableDeviceDbStore();
connection = Connection.openSerialPort('COM5');

%%
try
    %check the number of devices found
    deviceList = connection.detectDevices();
    if deviceList.length == 2
        fprintf("Found 2 devices, as expected.");
    elseif deviceList.length < 2
        fprintf('Found %d devices.\nExpect 2 for platform; unable to proceed.', deviceList.length);
        connection.close() %will stop the program from messing with device
        error("Connection error: expected platform with 2 devices, x and y motors")
    else
        fprintf('Found %d devices.\nExpect 2 for platform; proceed with caution', deviceList.length);
        proceed = input("Proceed? Y or N: ", 's');
        if proceed == "Y"
            fprintf("Proceeding. Caution Advised");
        else
            connection.close();
            error("Closed for device mismatch.");
        end
    end

    %%
    device_y = deviceList(1);
    %moves platform forward (pos) and back (neg)
    y_axis = device_y.getAxis(1);

    %x axis
    device_x = deviceList(2);
    %moves platform forward (pos) and back (neg)
    x_axis = device_x.getAxis(1);

    %now you''re set to move!
    y_axis.home();
    x_axis.home();

    %%
    % wait for user input
    % Run parameters here
    %
    % %%%%%%%%%%%%%%%
    n_rows = 3;
    n_cols = 6;
    y_accel = 20 % in Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED
    x_accel = 20 % in Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED


    %Units.LENGTH_MICROMETRES
    %Units.LENGTH_NANOMETRES
    units = Units.LENGTH_MILLIMETRES;
    x_distance = .1;
    y_distance = .1;
    % or specify total_distance
    %x_distance = width / (n_cols-1)
    %y_distance = length / (n_rows-1)

    time1 = 5; %seconds
    time_at_point = 15; %seconds
    %%n_rows = input("How many rows?"); %ie, 4
    %n_cols = input("How many columns?");
    %units = input("Units, ie Units.LENGTH_MILLIMETRES or Units.LENGTH_MICROMETRES");
    %width = input(sprintf("How wide is the field? (%u)",units));
    %length = input(sprintf("How long is the field? (%u)",units));
    %x_distance = width / (n_cols-1)
    %y_distance = length / (n_rows-1)


    %time_at_point = input("How long in each spot?");%.02; % seconds %ex 10 seconds
    %%%%%%%%%%%%
    %
    % end variables section

    %%
    %To avoid jerky movements, set acceleration ('accel') (and/or maxspeed)
    %Note that at the end the program should set it properly back to the initial values
    % Before I changed any of them, both accel is 59.5894 nits.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED
    % and both maxspeed are 5.9999 Units.VELOCITY_MILLIMETRES_PER_SECOND
    initial_accel_x = x_axis.getSettings().get('accel', Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED);
    axis.getSettings().set('accel', x_accel, Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED);
    fprintf('Maximum speed X[mm/s]: %d.\n', x_accel);

    initial_accel_y = axis.getSettings().get('accel', Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED);
    axis.getSettings().set('accel', y_accel, Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED);
    fprintf('Maximum speed X[mm/s]: %d.\n', y_accel);

    %%
    report = "Planned %d rows (%d %s between)\n  by %d columns (%d %s between) grid\npausing %.2f seconds at each location\n";

    fprintf(report, n_rows, x_distance, units, n_cols, y_distance, units, time_at_point)

    proceed = input("Proceed? Y or N: ", 's');
    if proceed == "Y"
        fprintf("Beginning movement.\n\n");
    else
        connection.close();
        error("Aborted.\n");
    end

    %%
    % calculate field points

    % DO NOT GO NEGATIVE!!
    %x_offset = (n_cols-1) * x_distance / 2;
    x_cors = 0:n_cols-1;
    x_cors = x_cors .* x_distance;

    %y_offset = (n_rows-1) * y_distance / 2;
    y_cors = 0:n_rows-1;
    y_cors = y_cors .* y_distance;

    %map=table(rowNames);

    %%
    run_at = datetime('now');

    schedule = table('Size',[n_rows*n_cols 4],'VariableTypes',{'double','double','double','double'},'VariableNames',{'ti','tf','x','y'});
    e = 0;

    %%
    %	go to top left of field
    tic
    for y=y_cors
        % go to y - move delta should also work, this would have better accuracy
        y_axis.moveAbsolute(y, units);

        for x=x_cors
            % go to x or move delta
            x_axis.moveAbsolute(x, units);
            ti = toc;
            %toc

            % record ti; pause for Δt; record tf
            %    To time the duration of an event, use the timeit or tic and toc functions
            %pause(time_at_point)

            java.lang.Thread.sleep(time1*1000);  % better accuracy at short times
            %laser on
            fprintf("Turn the laser on!\n")

            java.lang.Thread.sleep(time_at_point*1000);  % better accuracy at short times
            %laser off
            fprintf("Turn the laser off!\n")

            %pause

            tf = toc;
            e=e+1;
            schedule(e,:) = table(ti, tf, x,y);

        end
    end

    %%
    % go home
    y_axis.home();
    x_axis.home();

    connection.close();

    % record (ti, tf, x, y) schedule (may be redundant in image processing)
    output_file = sprintf("schedule_%s.txt", datestr(run_at, 'yyyy.mm.dd_HHMM.SS'));
    writetable(schedule, output_file,'Delimiter','\t');
    fprintf("\nSchedule saved to %s\nSuccess!", output_file);

    x_axis.getSettings().set('accel', initial_accel_x, Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED);
    y_axis.getSettings().set('accel', initial_accel_y, Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED);

catch exception
    %% This happens if there was any problem in the above section
    %   to make sure the connection closes anyway.
    fprintf("Fail\n")
    connection.close();
    rethrow(exception);
end
