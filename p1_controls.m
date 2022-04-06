classdef p1_controls
    methods (Static)

        %%
        function say_hi()
            fprintf("Hello World!\n")
        end


        %%
        function import_zaber()
            % This doesn''t actually seem to work
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;
            import zaber.motion.Library;
        end

        %%
        function connection = connect()
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;
            import zaber.motion.Library;
            %connect to device
            Library.enableDeviceDbStore();
            try
                connection = Connection.openSerialPort('COM5');
            catch
                connection = false;
            end
        end

        %%
        function validated_connection = validated_connection(connection)
            %check the number of devices found
            deviceList = connection.detectDevices();
            if deviceList.length == 2
                fprintf("Found 2 devices, as expected.\n");
                validated_connection = true;
            elseif deviceList.length < 2
                fprintf('Found %d devices.\nExpect 2 for platform; unable to proceed.', deviceList.length);
                validated_connection = false;
                connection.close() %will stop the program from messing with device
                error("Connection error: expected platform with 2 devices, x and y motors")
            else
                fprintf('Found %d devices.\nExpect 2 for platform; proceed with caution', deviceList.length);
                proceed = input("Proceed? Y or N: ", 's');
                if proceed == "Y"
                    fprintf("Proceeding. Caution Advised");
                    validated_connection = true;
                else
                    connection.close();
                    validated_connection = false;
                    error("Closed for device mismatch.");
                end
            end
        end

        %%
        function [x_axis, y_axis] = getAxes(connection)
            deviceList = connection.detectDevices();
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
        end

        %%
        function params = get_defaults()
            % wait for user input
            % Run parameters here
            %
            % %%%%%%%%%%%%%%%
            n_rows = 3;
            n_cols = 6;
            y_accel = 15; % in Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED
            x_accel = 15; % in Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED
            units_accel = Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED;


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

            params = struct('n_rows',n_rows, 'x_distance',x_distance, "n_cols",n_cols, ...
                        'y_distance',y_distance, 'units',units, 'time1',time1, ...
                        'time_at_point',time_at_point, 'x_accel',x_accel, ...
                         'y_accel',y_accel, 'units_accel',units_accel);
        end

        %%
        function  params = prompt_parameters()
            n_rows = input("How many rows?"); %ie, 4
            n_cols = input("How many columns?");
            units = input("Units, ie Units.LENGTH_MILLIMETRES or Units.LENGTH_MICROMETRES");
            width = input(sprintf("How wide is the field? (%u)",units));
            length = input(sprintf("How long is the field? (%u)",units));
            x_distance = width / (n_cols-1);
            y_distance = length / (n_rows-1);


            units_accel = input("Units for acceleration, i.e. Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED");
            x_accel = input(sprintf("X acceleration in (%u)",units_accel));
            y_accel = input(sprintf("Y acceleration in (%u)",units_accel));

            time1 = input("When should the laser be turned on or started?");
            time_at_point = input("How long in each spot?");%.02; % seconds %ex 10 seconds

            %
            % end variables section
            %%%%%%%%%%%%
            %%
            report = "Planned %d rows (%d %s between)\n  by %d columns (%d %s between) grid\npausing %.2f seconds at each location\n";

            fprintf(report, n_rows, x_distance, units, n_cols, y_distance, units, time_at_point)
            params = struct('n_rows',n_rows, 'x_distance',x_distance, "n_cols",n_cols, ...
                        'y_distance',y_distance, 'units',units, 'time1',time1, ...
                        'time_at_point',time_at_point, 'x_accel',x_accel, ...
                         'y_accel',y_accel, 'units_accel',units_accel);
        end

        %%
        function [initial_accel_x, initial_accel_y] = setAccel(x_axis, y_axis, x_accel, y_accel, units_accel)
            import zaber.motion.Units;

            unit_map = containers.Map('KeyType', 'char', 'ValueType','any');
            unit_map('METRES') = Units.ACCELERATION_METRES_PER_SECOND_SQUARED;
            unit_map('CENTIMETRES') = Units.ACCELERATION_CENTIMETRES_PER_SECOND_SQUARED;
            unit_map('MILLIMETRES') = Units.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED;
            unit_map('MICROMETRES') = Units.ACCELERATION_MICROMETRES_PER_SECOND_SQUARED;
            unit_map('NANOMETRES') = Units.ACCELERATION_NANOMETRES_PER_SECOND_SQUARED;

            unit_a = unit_map(units_accel);


            %To avoid jerky movements, set acceleration ('accel') (and/or maxspeed)
            %Note that at the end the program should set it properly back to the initial values
            % Before I changed any of them, both accel is 59.5894 nits.ACCELERATION_MILLIMETRES_PER_SECOND_SQUARED
            % and both maxspeed are 5.9999 Units.VELOCITY_MILLIMETRES_PER_SECOND
            initial_accel_x = x_axis.getSettings().get('accel', unit_a);
            x_axis.getSettings().set('accel', x_accel, unit_a);

            initial_accel_y = y_axis.getSettings().get('accel', unit_a);
            y_axis.getSettings().set('accel', y_accel, unit_a);
        end

        %%
        function point_order = scan_plan(n_rows, x_distance, n_cols, y_distance)
            % calculate field points
            x_cors = 0:n_cols-1;
            x_cors = x_cors .* x_distance;

            y_cors = 0:n_rows-1;
            y_cors = y_cors .* y_distance;

            %map=table(rowNames);
            point_order = table('Size',[n_rows*n_cols 4],'VariableTypes',{'double','double'},'VariableNames',{'x','y'});

            e=0
            for y=y_cors
                for x=x_cors
                    e=e+1;
                    schedule(e,:) = table(x,y);
                end
                x_cors=fliplr(x_cors)
            end
        end

        %%
        function output_file = run_scan(x_axis, y_axis, n_rows, x_distance, n_cols, y_distance, units_dist,...
                     time1, time_at_point)
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;
            import zaber.motion.Library;

            %% switch units
            unit_map = containers.Map('KeyType', 'char', 'ValueType','any');
            unit_map('METRES') = Units.LENGTH_METRES;
            unit_map('CENTIMETRES') = Units.LENGTH_CENTIMETRES;
            unit_map('MILLIMETRES') = Units.LENGTH_MILLIMETRES;
            unit_map('MICROMETRES') = Units.LENGTH_MICROMETRES;
            unit_map('NANOMETRES') = Units.LENGTH_NANOMETRES;

            unit_l = unit_map(units_dist);

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
                fprintf("Starting row %.2f\n", y/y_distance);
                % go to y - move delta should also work, this would have better accuracy
                y_axis.moveAbsolute(y, unit_l);

                for x=x_cors
                    % go to x or move delta
                    x_axis.moveAbsolute(x, unit_l);
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

                x_cors=fliplr(x_cors)
            end

            %%
            % go home
            y_axis.home();
            x_axis.home();

            %connection.close();

            % record (ti, tf, x, y) schedule (may be redundant in image processing)
            output_file = sprintf("schedule_%s.txt", datestr(run_at, 'yyyy.mm.dd_HHMM.SS'));
            writetable(schedule, output_file,'Delimiter','\t');
            fprintf("\nSchedule saved to %s\nSuccess!", output_file);
            fprintf("Don't forget to close the connection!");
        end

        %%
        function disconnect(connection)
            connection.close()
        end
    end
end
