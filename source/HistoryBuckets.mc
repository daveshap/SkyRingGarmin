import Toybox.Lang;

// Small, fixed-memory accumulator shared by the HR and stress sparklines.
// The caller supplies measured native history samples, never a held live value.
// A fresh instance anchors every rebuild to that refresh's UTC clock, including
// after a clock correction; missing/invalid samples remain gaps.
class HistoryBuckets {
    const COUNT = 24;
    const SPAN_SEC = 14400;
    const BUCKET_SEC = 600;

    private var mEnd as Number;
    private var mStart as Number;
    private var mMin as Numeric;
    private var mMax as Numeric;
    private var mSums as Array;
    private var mCounts as Array;

    function initialize(now as Number, minValue as Numeric, maxValue as Numeric) {
        mEnd = now;
        mStart = now - SPAN_SEC;
        mMin = minValue;
        mMax = maxValue;
        mSums = new [COUNT];
        mCounts = new [COUNT];
        for (var i = 0; i < COUNT; i++) {
            mSums[i] = 0;
            mCounts[i] = 0;
        }
    }

    // Inclusive window endpoints. An exact-now sample belongs to the final
    // bucket; each interior ten-minute boundary starts the following bucket.
    // SensorSample.data is Number/Float/null. Positive range comparisons also
    // reject non-finite values rather than letting them poison an average.
    function add(when, value) as Void {
        if (!(when instanceof Number) || when < mStart || when > mEnd
                || !(value instanceof Number || value instanceof Float)
                || !(value >= mMin && value <= mMax)) {
            return;
        }
        var index = (when - mStart) / BUCKET_SEC;
        if (index == COUNT) { index = COUNT - 1; }
        mSums[index] += value;
        mCounts[index] += 1;
    }

    // Oldest to newest. A measured stress zero is 0.0, not null.
    // Finish is repeatable and does not mutate the accumulated samples.
    function finish() as Array {
        var out = new [COUNT];
        for (var i = 0; i < COUNT; i++) {
            out[i] = mCounts[i] > 0 ? mSums[i].toFloat() / mCounts[i] : null;
        }
        return out;
    }
}
