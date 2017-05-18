using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Timer as Timer;
using Toybox.Time.Gregorian;

class PFaceView extends Ui.WatchFace
{
    enum {
        WALKING_ANIMATION, // ok
        HR_SAMPLE,
        STEP_COUNT, // ok
        ACTIVITY_PERC, // ok
        INTENSITY_MINUTES,
        NOTIFICATION_COUNT,
        ALARM_COUNT,
        DISTANCE, // ok
        FLOORS
    }

    hidden var fontDigits;
    hidden var fontDate;
    hidden var fontSz = 144;
    hidden var animationTimer;
    hidden var animFrame = 0;
    hidden var animFrameCount = 8;
    hidden var animWalk;
    hidden var devSettings;
    hidden var fillColor;
    hidden var backgroundColor;
    hidden var emptyColor;
    hidden var innerCircleColor;
    hidden var activityFill;
    hidden var showSeconds;
    hidden var circleData;
    hidden var circleFloat;


    hidden var circleRadius = 21;
    hidden var smallCircleRadiusPerc = 0.95;


    hidden var iconsFont;
    hidden var smallFieldFont;

    function loadSettings()
    {
        var appProp = Application.getApp();
        fillColor = appProp.getProperty("fillcolor");
        backgroundColor = appProp.getProperty("backcolor");
        emptyColor = appProp.getProperty("emptycolor");
        innerCircleColor = appProp.getProperty("innercirclecolor");
        activityFill = appProp.getProperty("activityFill");
        showSeconds = appProp.getProperty("showSeconds");
        circleData = appProp.getProperty("circleData");
        circleFloat = appProp.getProperty("circleFloat");


        if (circleData == WALKING_ANIMATION)
        {
            animWalk = [Ui.loadResource(Rez.Drawables.Walk0), Ui.loadResource(Rez.Drawables.Walk1),
            Ui.loadResource(Rez.Drawables.Walk2), Ui.loadResource(Rez.Drawables.Walk3),
            Ui.loadResource(Rez.Drawables.Walk4), Ui.loadResource(Rez.Drawables.Walk5),
            Ui.loadResource(Rez.Drawables.Walk6), Ui.loadResource(Rez.Drawables.Walk7)];

            animationTimer = new Timer.Timer();
        }
    }

    function drawField(dc, x, y)
    {
        if (circleData == WALKING_ANIMATION)
        {
            dc.drawBitmap(x -smallCircleRadiusPerc*circleRadius+1, y -smallCircleRadiusPerc*circleRadius+1, animWalk[animFrame]);
        }
        else
        {
            var strContent = "";
            var icon = "";

            var info = ActivityMonitor.getInfo();

            if (circleData == STEP_COUNT)
            {
                var steps = info.steps;

                if (steps >= 1000 && steps < 10000)
                {
                    strContent = Lang.format("$1$k", [(steps/1000.0).format("%.1f")]);
                }
                else if (steps >= 10000)
                {
                    strContent = Lang.format("$1$k", [(steps/1000).format("%d")]);
                }
                else
                {
                    strContent = Lang.format("$1$", [(steps).format("%d")]);
                }

                icon = "r";
            }
            else if (circleData == ACTIVITY_PERC)
            {
                var perc = (100*info.steps)/info.stepGoal;

                strContent = perc.toString() + "%";
                icon = "r";
            }
            else if (circleData == DISTANCE)
            {
                if (Sys.getDeviceSettings().distanceUnits == Sys.UNIT_METRIC)
                {
                    var dist = info.distance/100000.0;
                    if (dist >= 10)
                    {
                       strContent = Lang.format("$1$\nkm", [dist.format("%d")]);
                    }
                    else
                    {
                       strContent = Lang.format("$1$\nkm", [dist.format("%.1f")]);
                    }
                }
                else
                {
                    var dist = (info.distance*6.21371)/1000000;
                    if (dist >= 10)
                    {
                       strContent = Lang.format("$1$\nmi", [dist.format("%d")]);
                    }
                    else
                    {
                       strContent = Lang.format("$1$\nmi", [dist.format("%.1f")]);
                    }
                }
                icon = " ";
            }
            else if (info has :floorsClimbed && circleData == FLOORS)
            {
                strContent = info.floorsClimbed.toString();
                icon = "f";
            }
            else if(info has :activeMinutesDay && circleData == INTENSITY_MINUTES)
            {
                strContent = info.activeMinutesDay.total.toString() + "m";
                icon = "m";
            }
            else if(circleData == ALARM_COUNT)
            {
                strContent = Sys.getDeviceSettings().alarmCount.toString();
                icon = "a";
            }
            else if(circleData == NOTIFICATION_COUNT)
            {
                strContent = Sys.getDeviceSettings().notificationCount.toString();
                icon = "n";
            }
            else if(ActivityMonitor has :getHeartRateHistory && circleData == HR_SAMPLE)
            {
                strContent = ActivityMonitor.getHeartRateHistory(1, true).next().heartRate.toString();
                icon = "h";
            }
            else
            {
                strContent = "na";
                icon = " ";
            }

            var txtSz = dc.getTextDimensions(strContent, Gfx.FONT_XTINY);
            var iconSz = dc.getTextDimensions(icon, Gfx.FONT_XTINY);
            dc.setColor(emptyColor, Gfx.COLOR_TRANSPARENT);
            dc.drawText(x, y - 16, smallFieldFont, strContent, Gfx.TEXT_JUSTIFY_CENTER);
            if (icon != " ")
            {
                dc.drawText(x, y + 2, iconsFont, icon, Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    function drawSeconds(dc, x, y)
    {
        if (showSeconds)
        {
            // TODO: draw seconds
        }
    }
    function initialize()
    {
        WatchFace.initialize();
        devSettings = Sys.getDeviceSettings();
    }

    function onLayout(dc)
    {
        fontDigits = Ui.loadResource(Rez.Fonts.RobotoDigits);
        fontDate = Ui.loadResource(Rez.Fonts.RobotoRot);
        iconsFont = Ui.loadResource(Rez.Fonts.IconsFont);
        smallFieldFont =  Ui.loadResource(Rez.Fonts.RobotoSmall);

        self.loadSettings();
    }

    function animCallback()
    {
        animFrame++;
        animFrame%=animFrameCount;

        Ui.requestUpdate();
    }

    // Update the view
    function onUpdate(dc)
    {
        self.loadSettings();

        View.onUpdate(dc);
        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        var perc = 0;

        if (activityFill)
        {
            var infos = ActivityMonitor.getInfo();
            perc = infos.steps.toDouble()/infos.stepGoal.toDouble();
        }

        if (perc > 1)
        {
            perc = 1;
        }


        // Sys.println(perc);

        // Get and show the current time
        var clockTime = Sys.getClockTime();
        var date = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$", [date.day_of_week.toString().substring(0, 3), date.day]);
        
        var hour = clockTime.hour;

        if (!devSettings.is24Hour)
        {
            if (hour == 0)
            {
                hour = 12;
            }
            else if (hour > 12)
            {
                hour -= 12;
            }
        }

        var hourTime = Lang.format("$1$", [hour.format("%02d")]);
        var minTime = Lang.format("$1$", [clockTime.min.format("%02d")]);

        var hourSz = dc.getTextDimensions(hourTime, fontDigits);
        var minSz = dc.getTextDimensions(minTime, fontDigits);

        var hourTop = (h - hourSz[1] - minSz[1])/2;
        var hourLeft = w/3;

        var minTop = hourTop + hourSz[1];
        var minLeft = hourLeft;

        var lineY = hourTop + (1-perc)*(hourSz[1] + minSz[1]);

        var circleX = hourLeft - circleRadius + 3;
        var circleY = lineY;

        if (circleFloat)
        {
            if (lineY <= circleRadius/2)
            {
                circleY = circleRadius/1.5;
            }
            else if (lineY >= h - circleRadius/2)
            {
                circleY = h - circleRadius/1.5;
            }
        }

        var strLen = dateStr.length();
        var dateLeft = 0.07*w -1;
        var distChar = 22;
        var dateHeight = strLen*distChar;
        
        var dateTop = (h-dateHeight)/2 + 1;

        dc.setColor(fillColor, fillColor);
        dc.fillRectangle(hourLeft, hourTop+1, hourSz[0], hourSz[1] + minSz[1]);
        dc.fillRectangle(dateLeft, dateTop+1, 28, distChar*strLen);

        dc.setColor(emptyColor, emptyColor);
        dc.fillRectangle(hourLeft, hourTop+1, hourSz[0], (1-perc)*(hourSz[1] + minSz[1]));
        dc.fillRectangle(dateLeft, dateTop+1, 28, lineY-dateTop-1);

        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        dc.drawText(hourLeft, hourTop, fontDigits, hourTime, Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(minLeft, minTop, fontDigits, minTime, Gfx.TEXT_JUSTIFY_LEFT);

        var dateArray = dateStr.toCharArray();

        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        for (var i=strLen-1; i >= 0; i--)
        {
            var chSz = dc.getTextDimensions(dateArray[i].toString(), fontDate);

            dc.drawText(dateLeft, dateTop, fontDate, dateArray[i].toString(), Gfx.TEXT_JUSTIFY_LEFT);
            dateTop += distChar;
        }
        
        dc.setColor(backgroundColor, backgroundColor);
        dc.fillRectangle(dateLeft, dateTop+1, 28, h);

        if (activityFill)
        {
            dc.setColor(fillColor, fillColor);
            dc.setPenWidth(2);
            dc.drawLine(0, lineY, w, lineY);

            dc.fillCircle(circleX, circleY, circleRadius);
            dc.setColor(innerCircleColor, innerCircleColor);
            dc.fillCircle(circleX, circleY, smallCircleRadiusPerc*circleRadius);

            drawSeconds(dc, circleX , circleY);
            drawField(dc, circleX, circleY);
        }

        // Draw extra field for notifications, alarms, battery and "do not disturb"
        var iconsSz = 20;
        var iconsLeft = 0.93*w;
        var iconsTop = (h-iconsSz)/2;

        // Battery
        var battW = (iconsSz/1.618+1).toNumber();
        battW += (battW%2);
        var battTopW = battW/2;
        var battTopH = 3;

        var battPerc = Sys.getSystemStats().battery/100;

        if (battPerc < 0.25) // Low battery!
        {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
        }
        else
        {
            dc.setColor(emptyColor, emptyColor);
        }
        dc.fillRectangle(iconsLeft, iconsTop + (1-battPerc)*iconsSz, battW, battPerc*(iconsSz));

        dc.setColor(emptyColor, emptyColor);
        dc.fillRectangle(iconsLeft + (battW - battTopW)/2, iconsTop - battTopH, battTopW, battTopH);
        dc.drawRectangle(iconsLeft, iconsTop, battW, iconsSz);
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep()
    {
        // Start timer to draw the man :)
        if (animationTimer)
        {
            animationTimer.start(self.method(:animCallback), 130, true);
        }
    }


    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep()
    {
        if (animationTimer)
        {
            animationTimer.stop();
        }

        Ui.requestUpdate();
    }
}
