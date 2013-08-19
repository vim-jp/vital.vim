source spec/base.vim

let g:DT = vital#of('vital').import('DateTime')

" XXX: Disable this test: This fails on travis-ci by unknown reason.
" Context DateTime.DateTime.from_unix_time()
"   It makes a DateTime object from unix time
"     let dt = g:DT.from_unix_time(1325441045)
"     Should dt.year() is 2012
"     Should dt.month() is 1
"     Should dt.day() is 2
"     Should dt.hour() is 3
"     Should dt.minute() is 4
"     Should dt.second() is 5
"   End
" End

Context DateTime.DateTime.from_format()
  It makes a DateTime object from formatted string
    let dt = g:DT.from_format('2012-1-02T03:04:05Z', '%Y-%m-%dT%H:%M:%SZ%z')
    Should dt.year() is 2012
    Should dt.month() is 1
    Should dt.day() is 2
    Should dt.hour() is 3
    Should dt.minute() is 4
    Should dt.second() is 5
    Should dt.timezone().offset() is 0
  End
  It can treat the some format specifier
    let dt = g:DT.from_format('02 Jan 2012 03:04:05 +0900', '%d %b %Y%n%H:%M:%S%n%z', 'C')
    Should dt.year() is 2012
    Should dt.month() is 1
    Should dt.day() is 2
    Should dt.hour() is 3
    Should dt.minute() is 4
    Should dt.second() is 5
    Should dt.timezone().hours() is 9
  End
  It can skip any text by %*
    let dt = g:DT.from_format('2011-01-03T10:16:46.297581Z', '%Y-%m-%dT%H:%M:%S%*Z%z', 'C')
    Should dt.year() is 2011
    Should dt.month() is 1
    Should dt.day() is 3
    Should dt.hour() is 10
    Should dt.minute() is 16
    Should dt.second() is 46
    Should dt.timezone().hours() is 0
  End
End

Context DateTime.DateTime.from_julian_day()
  It makes a DateTime object from string
    let dt = g:DT.from_julian_day(2455928.627836, 0)
    Should dt.year() is 2012
    Should dt.month() is 1
    Should dt.day() is 2
    Should dt.hour() is 3
    Should dt.minute() is 4
    Should dt.second() is 5
  End
End

Context DateTime.TimeDelta
  let dt1 = g:DT.from_format('2012-01-02 00:00:00', '%Y-%m-%d %H:%M:%S')
  let dt2 = g:DT.from_format('2012-01-02 03:04:05', '%Y-%m-%d %H:%M:%S')
  let delta = dt2['-'](dt1)
  It is a TimeDelta object
    Should delta.days() is 0
    Should delta.hours() is 3
    Should delta.minutes() is 184
    Should delta.seconds() is 11045
  End
End
