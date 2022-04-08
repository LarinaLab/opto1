classdef scanUI_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        LeftPanel                    matlab.ui.container.Panel
        OutputEditField              matlab.ui.control.EditField
        OutputEditFieldLabel         matlab.ui.control.Label
        LaserPromptButton            matlab.ui.control.Button
        HomeButton                   matlab.ui.control.Button
        RunButton                    matlab.ui.control.Button
        Note1                        matlab.ui.control.Label
        time_per_locLabel            matlab.ui.control.Label
        time_at_loc_EditField        matlab.ui.control.NumericEditField
        AtlocationsecondsEditFieldLabel  matlab.ui.control.Label
        time_till_on_EditField       matlab.ui.control.NumericEditField
        TilllaseronsecondsEditFieldLabel  matlab.ui.control.Label
        RunParametersLabel           matlab.ui.control.Label
        UnitsAccel                   matlab.ui.control.DropDown
        UnitsDropDown_2Label         matlab.ui.control.Label
        xAccel                       matlab.ui.control.NumericEditField
        xAccelerationEditFieldLabel  matlab.ui.control.Label
        yAccel                       matlab.ui.control.NumericEditField
        yAccelerationEditFieldLabel  matlab.ui.control.Label
        UnitsDist                    matlab.ui.control.DropDown
        UnitsDropDownLabel           matlab.ui.control.Label
        xdelta                       matlab.ui.control.NumericEditField
        xdeltaEditFieldLabel         matlab.ui.control.Label
        ydelta                       matlab.ui.control.NumericEditField
        ydeltaEditField_2Label       matlab.ui.control.Label
        n_rows                       matlab.ui.control.NumericEditField
        NumberofRowsEditFieldLabel   matlab.ui.control.Label
        n_cols                       matlab.ui.control.NumericEditField
        NumberofColumnsEditField_3Label  matlab.ui.control.Label
        RightPanel                   matlab.ui.container.Panel
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            try
                %connect
                app.LaserPromptButton.Text = "Connecting";
                pause(0.01)
                connection = p1_controls.connect();
                if connection == false
                    %unable to connect
                    app.RunButton.BackgroundColor = 'red';
                    return
                end
                fprintf("connected\n")
                
                %check number of devices
                val = p1_controls.validated_connection(connection);
                if val == false
                    %can't do anything
                    %connection is closed
                    app.RunButton.BackgroundColor = [.9,.65,.15];
                    return
                end
                app.RunButton.BackgroundColor = [0.40,0.90,0.40];
                
                %get axes
                app.LaserPromptButton.Text = "Homing";
                pause(0.01)
                [x_axis, y_axis] = p1_controls.getAxes(connection);
                
                %set acceleration
                x_accel = app.xAccel.Value;
                y_accel = app.yAccel.Value;
                units_accel = app.UnitsAccel.Value;
                [initial_accel_x, initial_accel_y] = ...
                    p1_controls.setAccel(x_axis, y_axis, x_accel, y_accel, units_accel);
                
                app.LaserPromptButton.Text = "Ready";
                pause(0.01)
                
                %scan plan
                %movement
                out_to = app.OutputEditField.Value;
                output_file = p1_controls.run_scan(app, x_axis, y_axis, ...
                    app.n_rows.Value, app.xdelta.Value, ...
                    app.n_cols.Value, app.ydelta.Value, app.UnitsDist.Value,...
                    app.time_till_on_EditField.Value , app.time_at_loc_EditField.Value, ...
                    out_to);
                fprintf("\nSchedule saved to %s\nSuccess!\n", output_file);
            
                %reset acceleration
                p1_controls.setAccel(x_axis, y_axis, initial_accel_x, initial_accel_y, units_accel);

                connection.close()
                fprintf("\nDone.\n")
            catch exception
                % This happens if there was any problem in the above section
                %   to make sure the connection closes anyway.
                fprintf("Fail\n")
                connection.close();
                rethrow(exception);
            end            
        end

        % Button pushed function: HomeButton
        function HomeButtonPushed(app, event)
           try
                %connect
                app.LaserPromptButton.Text = "Connecting";
                pause(0.01)
                connection = p1_controls.connect();
                if connection == false
                    %unable to connect
                    app.RunButton.BackgroundColor = 'red';
                    return
                end
                fprintf("connected\n")
                
                %check number of devices
                val = p1_controls.validated_connection(connection);
                if val == false
                    %can't do anything
                    %connection is closed
                    app.RunButton.BackgroundColor = [.9,.65,.15];
                    return
                end
                app.RunButton.BackgroundColor = [0.40,0.90,0.40];
                
                %get axes
                app.LaserPromptButton.Text = "Homing";
                pause(0.01)
                [x_axis, y_axis] = p1_controls.getAxes(connection);
                
                %set acceleration
                x_accel = app.xAccel.Value;
                y_accel = app.yAccel.Value;
                units_accel = app.UnitsAccel.Value;
                [initial_accel_x, initial_accel_y] = ...
                    p1_controls.setAccel(x_axis, y_axis, x_accel, y_accel, units_accel);
                
                app.LaserPromptButton.Text = "Ready";
                pause(0.01)
                
                %reset acceleration
                p1_controls.setAccel(x_axis, y_axis, initial_accel_x, initial_accel_y, units_accel);

                connection.close()
                fprintf("\nDone.\n")
            catch exception
                % This happens if there was any problem in the above section
                %   to make sure the connection closes anyway.
                fprintf("Fail\n")
                connection.close();
                rethrow(exception);
           end
        end

        % Value changed function: time_at_loc_EditField, 
        % time_till_on_EditField
        function time_at_loc_EditFieldValueChanged(app, event)
          % check the times are sensible 
          if app.time_till_on_EditField.Value > app.time_at_loc_EditField.Value
              app.time_till_on_EditField.BackgroundColor = [.94,.94,.94];
          elseif app.time_till_on_EditField.Value == 0 
              app.time_till_on_EditField.BackgroundColor = [.94,.94,.94];
          else
              app.time_till_on_EditField.BackgroundColor = [1,1,1];
          end
        end

        % Button pushed function: LaserPromptButton
        function time_at_loc_EditFieldValueChanged2(app, event)
           app.LaserPromptButton.BackgroundColor = [.1, .8, .8];
           p1_controls.say_hi(app)
           
           pause(1)
           fprintf("Turn the laser on! . \n")
           app.LaserPromptButton.BackgroundColor = [0.3, 0.93, .97];
           app.LaserPromptButton.Text = "Turn the laser on!";

           pause(1)
           fprintf("Turn the laser off! . \n")
           app.LaserPromptButton.BackgroundColor = [.94,.94,.94];
           app.LaserPromptButton.Text = "Turn the laser off!";
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {633, 633};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {204, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 220 633];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {204, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create NumberofColumnsEditField_3Label
            app.NumberofColumnsEditField_3Label = uilabel(app.LeftPanel);
            app.NumberofColumnsEditField_3Label.HorizontalAlignment = 'right';
            app.NumberofColumnsEditField_3Label.Position = [12 511 112 17];
            app.NumberofColumnsEditField_3Label.Text = 'Number of Columns';

            % Create n_cols
            app.n_cols = uieditfield(app.LeftPanel, 'numeric');
            app.n_cols.Limits = [0 Inf];
            app.n_cols.Position = [139 510 45 18];
            app.n_cols.Value = 6;

            % Create NumberofRowsEditFieldLabel
            app.NumberofRowsEditFieldLabel = uilabel(app.LeftPanel);
            app.NumberofRowsEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofRowsEditFieldLabel.Position = [12 530 112 22];
            app.NumberofRowsEditFieldLabel.Text = 'Number of Rows';

            % Create n_rows
            app.n_rows = uieditfield(app.LeftPanel, 'numeric');
            app.n_rows.Limits = [0 Inf];
            app.n_rows.Position = [139 534 45 18];
            app.n_rows.Value = 3;

            % Create ydeltaEditField_2Label
            app.ydeltaEditField_2Label = uilabel(app.LeftPanel);
            app.ydeltaEditField_2Label.HorizontalAlignment = 'right';
            app.ydeltaEditField_2Label.Position = [13 443 112 22];
            app.ydeltaEditField_2Label.Text = 'y delta';

            % Create ydelta
            app.ydelta = uieditfield(app.LeftPanel, 'numeric');
            app.ydelta.Limits = [0 Inf];
            app.ydelta.Position = [140 447 45 18];
            app.ydelta.Value = 0.5;

            % Create xdeltaEditFieldLabel
            app.xdeltaEditFieldLabel = uilabel(app.LeftPanel);
            app.xdeltaEditFieldLabel.HorizontalAlignment = 'right';
            app.xdeltaEditFieldLabel.Position = [13 420 112 22];
            app.xdeltaEditFieldLabel.Text = 'x delta';

            % Create xdelta
            app.xdelta = uieditfield(app.LeftPanel, 'numeric');
            app.xdelta.Limits = [0 Inf];
            app.xdelta.Position = [140 424 45 18];
            app.xdelta.Value = 0.5;

            % Create UnitsDropDownLabel
            app.UnitsDropDownLabel = uilabel(app.LeftPanel);
            app.UnitsDropDownLabel.HorizontalAlignment = 'right';
            app.UnitsDropDownLabel.Position = [13 470 33 22];
            app.UnitsDropDownLabel.Text = 'Units';

            % Create UnitsDist
            app.UnitsDist = uidropdown(app.LeftPanel);
            app.UnitsDist.Items = {'METRES', 'CENTIMETRES', 'MILLIMETRES', 'MICROMETRES', 'NANOMETRES'};
            app.UnitsDist.Position = [61 470 123 22];
            app.UnitsDist.Value = 'MILLIMETRES';

            % Create yAccelerationEditFieldLabel
            app.yAccelerationEditFieldLabel = uilabel(app.LeftPanel);
            app.yAccelerationEditFieldLabel.HorizontalAlignment = 'right';
            app.yAccelerationEditFieldLabel.Position = [16 357 112 22];
            app.yAccelerationEditFieldLabel.Text = 'y Acceleration';

            % Create yAccel
            app.yAccel = uieditfield(app.LeftPanel, 'numeric');
            app.yAccel.Limits = [0.001 59.5894];
            app.yAccel.Position = [143 361 45 18];
            app.yAccel.Value = 15;

            % Create xAccelerationEditFieldLabel
            app.xAccelerationEditFieldLabel = uilabel(app.LeftPanel);
            app.xAccelerationEditFieldLabel.HorizontalAlignment = 'right';
            app.xAccelerationEditFieldLabel.Position = [16 334 112 22];
            app.xAccelerationEditFieldLabel.Text = 'x Acceleration';

            % Create xAccel
            app.xAccel = uieditfield(app.LeftPanel, 'numeric');
            app.xAccel.Limits = [0.001 59.5894];
            app.xAccel.Position = [143 338 45 18];
            app.xAccel.Value = 15;

            % Create UnitsDropDown_2Label
            app.UnitsDropDown_2Label = uilabel(app.LeftPanel);
            app.UnitsDropDown_2Label.HorizontalAlignment = 'right';
            app.UnitsDropDown_2Label.Position = [16 384 33 22];
            app.UnitsDropDown_2Label.Text = 'Units';

            % Create UnitsAccel
            app.UnitsAccel = uidropdown(app.LeftPanel);
            app.UnitsAccel.Items = {'CENTIMETRES', 'MILLIMETRES', 'MICROMETRES', 'NANOMETRES'};
            app.UnitsAccel.Position = [64 384 123 22];
            app.UnitsAccel.Value = 'MILLIMETRES';

            % Create RunParametersLabel
            app.RunParametersLabel = uilabel(app.LeftPanel);
            app.RunParametersLabel.FontSize = 20;
            app.RunParametersLabel.Position = [25 581 151 24];
            app.RunParametersLabel.Text = 'Run Parameters';

            % Create TilllaseronsecondsEditFieldLabel
            app.TilllaseronsecondsEditFieldLabel = uilabel(app.LeftPanel);
            app.TilllaseronsecondsEditFieldLabel.HorizontalAlignment = 'right';
            app.TilllaseronsecondsEditFieldLabel.Position = [7 263 122 22];
            app.TilllaseronsecondsEditFieldLabel.Text = 'Till laser on (seconds)';

            % Create time_till_on_EditField
            app.time_till_on_EditField = uieditfield(app.LeftPanel, 'numeric');
            app.time_till_on_EditField.Limits = [0 Inf];
            app.time_till_on_EditField.ValueChangedFcn = createCallbackFcn(app, @time_at_loc_EditFieldValueChanged, true);
            app.time_till_on_EditField.Tooltip = {'Note that time till laser on refers to when on instruction is sent. There will be a ~5 second delay till the laser hits the sample.'};
            app.time_till_on_EditField.Position = [144 266 45 18];
            app.time_till_on_EditField.Value = 0.1;

            % Create AtlocationsecondsEditFieldLabel
            app.AtlocationsecondsEditFieldLabel = uilabel(app.LeftPanel);
            app.AtlocationsecondsEditFieldLabel.HorizontalAlignment = 'right';
            app.AtlocationsecondsEditFieldLabel.Position = [11 240 118 22];
            app.AtlocationsecondsEditFieldLabel.Text = 'At location (seconds)';

            % Create time_at_loc_EditField
            app.time_at_loc_EditField = uieditfield(app.LeftPanel, 'numeric');
            app.time_at_loc_EditField.Limits = [0 Inf];
            app.time_at_loc_EditField.ValueChangedFcn = createCallbackFcn(app, @time_at_loc_EditFieldValueChanged, true);
            app.time_at_loc_EditField.Position = [144 243 45 18];
            app.time_at_loc_EditField.Value = 0.2;

            % Create time_per_locLabel
            app.time_per_locLabel = uilabel(app.LeftPanel);
            app.time_per_locLabel.Position = [54 284 97 22];
            app.time_per_locLabel.Text = 'Time per location';

            % Create Note1
            app.Note1 = uilabel(app.LeftPanel);
            app.Note1.WordWrap = 'on';
            app.Note1.Tooltip = {'Note that time till laser on refers to '};
            app.Note1.Position = [7 185 192 56];
            app.Note1.Text = 'Note that time till laser on refers to when on instruction is sent.     There will be a 5 second delay till the laser hits the sample.';

            % Create RunButton
            app.RunButton = uibutton(app.LeftPanel, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.BackgroundColor = [0.4 0.902 0.4];
            app.RunButton.FontSize = 15;
            app.RunButton.FontWeight = 'bold';
            app.RunButton.Position = [51 25 106 29];
            app.RunButton.Text = 'Run';

            % Create HomeButton
            app.HomeButton = uibutton(app.LeftPanel, 'push');
            app.HomeButton.ButtonPushedFcn = createCallbackFcn(app, @HomeButtonPushed, true);
            app.HomeButton.BackgroundColor = [0.8 0.8 0.8];
            app.HomeButton.FontSize = 15;
            app.HomeButton.FontWeight = 'bold';
            app.HomeButton.Position = [52 63 106 29];
            app.HomeButton.Text = 'Home';

            % Create LaserPromptButton
            app.LaserPromptButton = uibutton(app.LeftPanel, 'push');
            app.LaserPromptButton.ButtonPushedFcn = createCallbackFcn(app, @time_at_loc_EditFieldValueChanged2, true);
            app.LaserPromptButton.Position = [51 109 107 22];
            app.LaserPromptButton.Text = '--';

            % Create OutputEditFieldLabel
            app.OutputEditFieldLabel = uilabel(app.LeftPanel);
            app.OutputEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputEditFieldLabel.Position = [11 147 38 22];
            app.OutputEditFieldLabel.Text = 'Output';

            % Create OutputEditField
            app.OutputEditField = uieditfield(app.LeftPanel, 'text');
            app.OutputEditField.Position = [54 147 144 22];
            app.OutputEditField.Value = 'D:\Michaela\opto1\test';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = scanUI_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end