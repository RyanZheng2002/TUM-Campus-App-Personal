//
//  CalendarWidgetEntry.swift
//  CalendarWidgetExtension
//
//  Created by Jakob Körber on 01.02.24.
//

import WidgetKit
import SwiftUI

struct CalendarWidgetEntry: TimelineEntry {
    let date: Date
    let entries: [CalendarEntry]
    let size: WidgetFamily
}
