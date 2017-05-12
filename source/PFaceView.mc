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
    hidden var fontDigits;
    hidden var fontDate;
    hidden var fontSz = 144;
    hidden var animationTimer;
    hidden var animFrame = 0;
    hidden var animFrameCount = 8;
    hidden var animWalk;
    hidden var devSettings;
    hidden var fillColor = Gfx.COLOR_BLUE;
    hidden var backgroundColor = Gfx.COLOR_BLACK;
    hidden var emptyColor = Gfx.COLOR_WHITE;
    hidden var innerCircleColor = Gfx.COLOR_DK_GRAY;

    function initialize()
    {
        WatchFace.initialize();
        devSettings = Sys.getDeviceSettings();
    }

    function onLayout(dc)
    {
        fontDigits = Ui.loadResource(Rez.Fonts.RobotoDigits);
        fontDate = Ui.loadResource(Rez.Fonts.RobotoRot);

        animWalk = [Ui.loadResource(Rez.Drawables.Walk0), Ui.loadResource(Rez.Drawables.Walk1),
        Ui.loadResource(Rez.Drawables.Walk2), Ui.loadResource(Rez.Drawables.Walk3),
        Ui.loadResource(Rez.Drawables.Walk4), Ui.loadResource(Rez.Drawables.Walk5),
        Ui.loadResource(Rez.Drawables.Walk6), Ui.loadResource(Rez.Drawables.Walk7)];

        animationTimer = new Timer.Timer();
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
        View.onUpdate(dc);
        dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColor);
        
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        var infos = ActivityMonitor.getInfo();
        var perc = infos.steps.toDouble()/infos.stepGoal.toDouble();

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

        var circleRadius = 18;
        var circleX = hourLeft - circleRadius + 1;
        var circleY = lineY;
        var smallCircleRadiusPerc = 0.9;

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


        dc.setColor(fillColor, fillColor);
        dc.setPenWidth(2);
        dc.drawLine(0, lineY, w, lineY);

        dc.fillCircle(circleX, circleY, circleRadius);

        dc.setColor(innerCircleColor, innerCircleColor);
        dc.fillCircle(circleX, circleY, smallCircleRadiusPerc*circleRadius);

        dc.drawBitmap(circleX - smallCircleRadiusPerc*circleRadius + 1, circleY - smallCircleRadiusPerc*circleRadius + 1, animWalk[animFrame]);

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
        animationTimer.start(self.method(:animCallback), 130, true);
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
