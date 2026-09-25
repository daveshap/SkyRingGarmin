import Toybox.Lang;
import Toybox.Math;

// Rolling steps use local calendar dates, not seven records or elapsed 24-hour
// intervals. The latter both fail when history is sparse or a DST day is 23 h.
module DaySteps {
    var beforeMonth as Array<Number> = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

    function dayNumber(year as Number, month as Number, day as Number) as Number {
        var y = year - 1;
        var total = 365 * y + Math.floor(y / 4.0d).toNumber()
            - Math.floor(y / 100.0d).toNumber() + Math.floor(y / 400.0d).toNumber()
            + beforeMonth[month - 1] + day;
        if (month > 2 && year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
            total += 1;
        }
        return total;
    }

    // Each input record is [serial local date, steps, optional step goal].
    // The original three-argument entry point keeps callers without goals valid.
    function summarize(today as Number, liveSteps, records as Array) as Dictionary {
        return summarizeWithGoals(today, liveSteps, null, records);
    }

    // Null means unavailable;
    // an explicit zero is a valid measured day. Ignore duplicates, future days,
    // older days, and today's history because the live counter owns today.
    // Goals belong to the same accepted daily record as the steps. In particular,
    // today's adaptive goal must never be substituted for an unknown past goal.
    function summarizeWithGoals(today as Number, liveSteps, liveGoal, records as Array) as Dictionary {
        var bars = new [7] as Array<Number or Null>;
        var goals = new [7] as Array<Number or Null>;
        for (var i = 0; i < 7; i++) { bars[i] = null; goals[i] = null; }
        if (liveSteps instanceof Number && liveSteps >= 0) {
            bars[6] = liveSteps;
            if (liveGoal instanceof Number && liveGoal > 0) { goals[6] = liveGoal; }
        }
        for (var j = 0; j < records.size(); j++) {
            var r = records[j];
            if (!(r instanceof Array) || r.size() < 2 || r.size() > 3
                    || !(r[0] instanceof Number) || !(r[1] instanceof Number) || r[1] < 0) {
                continue;
            }
            var index = r[0] - today + 6;
            if (index >= 0 && index < 6 && bars[index] == null) {
                bars[index] = r[1];
                if (r.size() == 3 && r[2] instanceof Number && r[2] > 0) {
                    goals[index] = r[2];
                }
            }
        }
        var total = 0;
        var found = 0;
        for (var k = 0; k < 7; k++) {
            if (bars[k] != null) {
                total += bars[k];
                found += 1;
            }
        }
        return {:sum => found > 0 ? total : null, :count => found,
                :complete => found == 7, :bars => bars, :goals => goals};
    }
}
