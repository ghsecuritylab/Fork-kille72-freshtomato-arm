<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<!--
	Tomato GUI
	Copyright (C) 2006-2010 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] Bandwidth: Real-Time</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<script type="text/javascript" src="tomato.js"></script>

<!-- / / / -->

<style type="text/css">
#txt {
	width: 550px;
	white-space: nowrap;
}
#bwm-controls {
	text-align: right;
	margin-right: 5px;
	margin-top: 5px;
	float: right;
	visibility: hidden;
}
</style>

<script type="text/javascript" src="debug.js"></script>

<script type="text/javascript" src="wireless.jsx?_http_id=<% nv(http_id); %>"></script>
<script type="text/javascript" src="bwm-common.js"></script>
<script type="text/javascript" src="bwm-hist.js"></script>
<script type="text/javascript" src="interfaces.js"></script>

<script type="text/javascript">
//	<% nvram("wan_ifname,wan_iface,wan2_ifname,wan2_iface,wan3_ifname,wan3_iface,wan4_ifname,wan4_iface,lan_ifname,lan1_ifname,lan2_ifname,lan3_ifname,wan_proto,wan2_proto,wan3_proto,wan4_proto,web_svg,rstats_colors,rstats_enable"); %>

var cprefix = 'bw_r';
var updateInt = 2;
var updateDiv = updateInt;
var updateMaxL = 300;
var updateReTotal = 1;
var prev = [];
var debugTime = 0;
var avgMode = 0;
var unitMode = 0;
var wdog = null;
var wdogWarn = null;
var rstats_busy = 0;

var ref = new TomatoRefresh('update.cgi', 'exec=netdev', updateInt);

ref.stop = function() {
	this.timer.start(1000);
}

ref.refresh = function(text) {
	var c, i, h, n, j, k;

	watchdogReset();

	++updating;
	try {
		netdev = null;
		eval(text);

		n = (new Date()).getTime();
		if (this.timeExpect) {
			if (debugTime) E('dtime').innerHTML = (this.timeExpect - n) + ' ' + ((this.timeExpect + 1000*updateInt) - n);
			this.timeExpect += 1000*updateInt;
			this.refreshTime = MAX(this.timeExpect - n, 500);
		}
		else {
			this.timeExpect = n + 1000*updateInt;
		}

		for (i in netdev) {
			c = netdev[i];
			if ((p = prev[i]) != null) {
				h = speed_history[i];

				h.rx.splice(0, 1);
				h.rx.push((c.rx < p.rx) ? (c.rx + (0xFFFFFFFF - p.rx + 0x00000001)) : (c.rx - p.rx));

				h.tx.splice(0, 1);
				h.tx.push((c.tx < p.tx) ? (c.tx + (0xFFFFFFFF - p.tx + 0x00000001)) : (c.tx - p.tx));
			}
			else if (!speed_history[i]) {
				speed_history[i] = {};
				h = speed_history[i];
				h.rx = [];
				h.tx = [];
				for (j = 300; j > 0; --j) {
					h.rx.push(0);
					h.tx.push(0);
				}
				h.count = 0;
			}
			prev[i] = c;
		}
		loadData();
	}
	catch (ex) {
	}
	--updating;
}

function watchdog() {
	watchdogReset();
	ref.stop();
	wdogWarn.style.display = '';
}

function watchdogReset() {
	if (wdog) clearTimeout(wdog)
	wdog = setTimeout(watchdog, 5000*updateInt);
	wdogWarn.style.display = 'none';
}

function init() {
	if (nvram.rstats_enable != '1') return;
	speed_history = [];

	initCommon(2, 1, 1, 1);

	wdogWarn = E('warnwd');
	watchdogReset();

	ref.start();
}
</script>

</head>
<body onload="init()">
<form action="">
<table id="container" cellspacing="0">
<tr><td colspan="2" id="header">
	<div class="title">Tomato</div>
	<div class="version">Version <% version(); %></div>
</td></tr>
<tr id="body"><td id="navi"><script type="text/javascript">navi()</script></td>
<td id="content">
<div id="ident"><% ident(); %></div>

<!-- / / / -->

<div class="section-title">WAN Bandwidth - Real-Time</div>
<div id="rstats">
	<div id="tab-area"></div>

	<script type="text/javascript">
	if ((nvram.web_svg != '0') && (nvram.rstats_enable == '1')) {
		W('<div style="border-top:1px solid #f0f0f0;border-bottom:1px solid #f0f0f0;visibility:hidden;padding:0;margin:0" id="graph"><embed src="bwm-graph.svg?<% version(); %>" style="width:760px;height:300px;margin:0;padding:0" type="image/svg+xml"><\/embed><\/div>\n');
	}
	</script>

	<div id="bwm-controls">
		<small>(10 minute window, 2 second interval)</small><br/>
		<br/>
		Avg:&nbsp;
			<a href="javascript:switchAvg(1)" id="avg1">Off</a>,
			<a href="javascript:switchAvg(2)" id="avg2">2x</a>,
			<a href="javascript:switchAvg(4)" id="avg4">4x</a>,
			<a href="javascript:switchAvg(6)" id="avg6">6x</a>,
			<a href="javascript:switchAvg(8)" id="avg8">8x</a><br/>
		Max:&nbsp;
			<a href="javascript:switchScale(0)" id="scale0">Uniform</a>,
			<a href="javascript:switchScale(1)" id="scale1">Per IF</a><br/>
		Unit:&nbsp;
			<a href="javascript:switchUnit(0)" id="unit0">kbit/KB</a>,
			<a href="javascript:switchUnit(1)" id="unit1">Mbit/MB</a><br/>
		Display:&nbsp;
			<a href="javascript:switchDraw(0)" id="draw0">Solid</a>,
			<a href="javascript:switchDraw(1)" id="draw1">Line</a><br/>
		Color:&nbsp; <a href="javascript:switchColor()" id="drawcolor">-</a><br/>
		<small><a href="javascript:switchColor(1)" id="drawrev">[reverse]</a></small><br/>

		<br/><br/>
		&nbsp; &raquo; <a href="admin-bwm.asp">Configure</a>
	</div>

	<br/><br/>
	<table id="txt" style="border-style:none;border-collapse:separate;border-spacing:2px">
	<tr>
		<td style="width:8%;text-align:right;vertical-align:top"><b style="border-bottom:blue 1px solid" id="rx-name">RX</b></td>
		<td style="width:15%;text-align:right;vertical-align:top"><span id="rx-current"></span></td>
		<td style="width:8%;text-align:right;vertical-align:top"><b>Avg</b></td>
		<td style="width:15%;text-align:right;vertical-align:top" id="rx-avg"></td>
		<td style="width:8%;text-align:right;vertical-align:top"><b>Peak</b></td>
		<td style="width:15%;text-align:right;vertical-align:top" id="rx-max"></td>
		<td style="width:8%;text-align:right;vertical-align:top"><b>Total</b></td>
		<td style="width:14%;text-align:right;vertical-align:top" id="rx-total"></td>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td style="width:8%;text-align:right;vertical-align:top"><b style="border-bottom:blue 1px solid" id="tx-name">TX</b></td>
		<td style="width:15%;text-align:right;vertical-align:top"><span id="tx-current"></span></td>
		<td style="width:8%;text-align:right;vertical-align:top"><b>Avg</b></td>
		<td style="width:15%;text-align:right;vertical-align:top" id="tx-avg"></td>
		<td style="width:8%;text-align:right;vertical-align:top"><b>Peak</b></td>
		<td style="width:15%;text-align:right;vertical-align:top" id="tx-max"></td>
		<td style="width:8%;text-align:right;vertical-align:top"><b>Total</b></td>
		<td style="width:14%;text-align:right;vertical-align:top" id="tx-total"></td>
		<td>&nbsp;</td>
	</tr>
	</table>
</div>


<script type="text/javascript">checkRstats();</script>

<!-- / / / -->

</td></tr>
<tr><td id="footer" colspan="2">
	<span id="warnwd" style="display:none">Warning: 10 second timeout, restarting...&nbsp;</span>
	<span id="dtime"></span>
	<img src="spin.gif" id="refresh-spinner" alt="" onclick="debugTime=1">
</td></tr>
</table>
</form>
</body>
</html>