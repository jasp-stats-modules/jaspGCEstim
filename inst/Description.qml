import QtQuick
import JASP.Module

Description
{
	name		: "jaspGCEstim"
	title		: qsTr("GCEstim")
	description	: qsTr("Entropy-based linear regression using GCEstim.")
	version		: "0.0.4"
	author		: "Jorge Cabral"
	maintainer	: "Jorge Cabral <jorgecabral@ua.pt>"
	website		: "https://github.com/jorgevazcabral/GCEstim"
	license		: "GPL-3"
	icon		: "GCEstim.svg"
	hasWrappers	: true

	Analysis
	{
		title:	"W-GCE Linear Model"
		menu:	"W-GCE"
		qml:	"Wgce.qml"
		func:	"wgce"
	}
	Analysis
	{
		title:	"TARW-GCE Linear Model"
		menu:	"TARW-GCE"
		qml:	"Tarwgce.qml"
		func:	"tarwgce"
	}
	Analysis
	{
		title:	"TASW-GCE Linear Model"
		menu:	"TASW-GCE"
		qml:	"Taswgce.qml"
		func:	"taswgce"
	}
}
