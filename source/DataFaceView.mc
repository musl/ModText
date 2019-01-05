using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.WatchUi;

class DataFaceView extends WatchUi.WatchFace {

	const halfPi = Math.PI / 2.0;
	const twoPi = Math.PI * 2.0;

	var time;
	var date;
	var hourOffset;
	var actInfo;
	var heartRateHistory;
	var heartRate;
	var elevationHistory;
	var elevation;
	var pressureHistory;
	var pressure;
	var temperatureHistory;
	var temperature;
	var stats;
	var settings;
	var width;
	var height;
	var centerX;
	var centerY;
	var textCenterY;
	var fontTime;
	var fontSmall;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
	    // Load your resources here
        fontTime = WatchUi.loadResource(Rez.Fonts.SCPS64N);
        fontSmall = WatchUi.loadResource(Rez.Fonts.SCPS32A);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }
    
    // Update the view
    // TODO: consider using an off-screen buffer here and drawing everything ourselves instead of using the insane layout xml.
    function onUpdate(dc) {
        width = dc.getWidth();
        height = dc.getHeight();
        centerX = width / 2;
        centerY = height / 2;
        textCenterY = centerY - 4;

        time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        hourOffset = (!System.getDeviceSettings().is24Hour && time.hour > 12) ? -12 : 0;
        date = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

        actInfo = ActivityMonitor.getInfo();
        stats = System.getSystemStats();
        settings = System.getDeviceSettings();

        heartRateHistory = ActivityMonitor.getHeartRateHistory(null, true);
		heartRate = heartRateHistory.next();
		
        elevationHistory = SensorHistory.getElevationHistory(null);
		elevation = elevationHistory.next();

        pressureHistory = SensorHistory.getPressureHistory(null);
		pressure = pressureHistory.next();

        temperatureHistory = SensorHistory.getTemperatureHistory(null);
		temperature = temperatureHistory.next();

		/*
		// TODO: MAKE THEMES
		bg = Application.getApp().getProperty("BackgroundColor");
		fg = Application.getApp().getProperty("ForegroundColor");
		*/
		
        dc.clearClip();
		dc.setColor(0, 0);
		dc.fillRectangle(0, 0, width, height);

		var n, x1, x2, y1, y2;
		var m = 120;
		var p = 2.0 * Math.PI / m;
		
		dc.setPenWidth(1);
		for(var i = 0; i < m; i++) {
			n = time.min * i % m;
			
			x1 = centerX + centerX * Math.cos(i * p);	
			y1 = centerY + centerY * Math.sin(i * p);	

			x2 = centerX + centerX * Math.cos(n * p);
			y2 = centerY + centerY * Math.sin(n * p);

			dc.setColor(0x000030, Graphics.COLOR_TRANSPARENT);
			dc.drawLine(x1, y1, x2, y2);
		}

		drawTime(dc);

		// TODO: find more things to display
		dc.setColor(0x004000, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			centerX,
			textCenterY - 105,
			fontSmall,
			Lang.format("$1$$2$", [
				elevation.data.format("%05d"),
				"\u25b2"
			]),
			Graphics.TEXT_JUSTIFY_CENTER
		);
		
		var distanceUnit = "km";
		var distance = actInfo.distance;
		switch(settings.distanceUnits) {
			case System.UNIT_STATUTE:
				distanceUnit = "mi";
				distance /= 160934.0;
				break;
			case System.UNIT_METRIC:
				distanceUnit = "km";
				distance /= 100000.0;
				break;
			default:
				distanceUnit = "km";
				distance /= 100000.0;
				break;
		}

		// TODO: find more things to display
		dc.setColor(0x008000, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			centerX,
			textCenterY - 78,
			fontSmall,
			Lang.format("$1$% $2$$3$", [
				(actInfo.activeMinutesWeek.total.toDouble() / actInfo.activeMinutesWeekGoal).format("%03d"),
				distance.format("%3.1f"),
				distanceUnit
			]),
			Graphics.TEXT_JUSTIFY_CENTER
		);	

		dc.setColor(0x00ff00, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			centerX,
			textCenterY - 50,
			fontSmall,
			Lang.format("$1$ $2$-$3$-$4$", [
				date.day_of_week,
				time.year.format("%04d"),
				time.month.format("%02d"),
				time.day.format("%02d")
			]),
			Graphics.TEXT_JUSTIFY_CENTER
		);	

		dc.setColor(0x00ff00, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			centerX,
			textCenterY + 23,
			fontSmall,
			Lang.format("$1$$2$ $3$%$4$ $5$*", [
				temperature.data.format("%02d"),
				"\u00b0",
        		(stats.battery + 0.5).format("%03d"),
				stats.charging ? "\u25b4" : "\u25be",
				settings.notificationCount.format("%03d")
			]),
			Graphics.TEXT_JUSTIFY_CENTER
		);	

		// double arrow down, arrow down, triangle down, triangle up, arrow up, double arrow up.
		var activitySymbols = ["\u21d1", "\u2191", "\u25b5", "\u25bf", "\u2193", "\u21d3"];

		dc.setColor(0x008000, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			centerX,
			textCenterY + 51,
			fontSmall,
			Lang.format("$1$% $2$ $3$\u2665", [
				(actInfo.steps.toDouble() / actInfo.stepGoal).format("%03d"),
				activitySymbols[actInfo.moveBarLevel],
				(heartRate.heartRate != ActivityMonitor.INVALID_HR_SAMPLE && heartRate.heartRate > 0) ?
					heartRate.heartRate.format("%03d") :
					"---",
			]),
			Graphics.TEXT_JUSTIFY_CENTER
		);	

		dc.setColor(0x004000, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			centerX,
			textCenterY + 78, 
			fontSmall,
			Lang.format("$1$$2$", [
				(pressure.data / 100.0).format("%04d"),
				"\u25c9"
			]),
			Graphics.TEXT_JUSTIFY_CENTER
		);	

		//View.onUpdate(dc);
    }
    
    // dc.clearClip() doesn't work here; do it at the top of each minute update.
    function onPartialUpdate(dc) {
        time = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        hourOffset = (!System.getDeviceSettings().is24Hour && time.hour > 12) ? -12 : 0;

		dc.setClip(centerX + 61, textCenterY - 15, 56, 35);
		dc.setColor(0, 0);
		dc.clear();

    	drawTime(dc);	
    }
    
    function drawTime(dc) {
		dc.setColor(0x40ff40, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			centerX,
			textCenterY,
			fontTime,
			Lang.format("$1$:$2$:$3$", [
				(time.hour + hourOffset).format(System.getDeviceSettings().is24Hour ? "%02d" : "%2d"),
				time.min.format("%02d"),
				time.sec.format("%02d")
			]),
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}