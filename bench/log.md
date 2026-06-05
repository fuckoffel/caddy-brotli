```
LEVEL=3 DURATION=60s ./bench.sh both

file: amazon.html   br level: 3   zstd level: default   concurrency: 2   duration: 60s

encoder          raw compressed    ratio        req/s
-------          --- ----------    -----        -----
>> this: starting caddy-this
>> baseline: hey zstd (-c 2 -z 60s)
zstd          830549     166831    0.201        372.6
>> this: hey br (-c 2 -z 60s)
this          830549     161953    0.195        369.1
>> ueffel: starting caddy-ueffel
>> ueffel: hey br (-c 2 -z 60s)
ueffel        830549     162042    0.195        189.2


LEVEL=4 ZLEVEL=better DURATION=60s ./bench.sh both

file: amazon.html   br level: 4   zstd level: better   concurrency: 2   duration: 60s

encoder          raw compressed    ratio        req/s
-------          --- ----------    -----        -----
>> this: starting caddy-this
>> baseline: hey zstd (-c 2 -z 60s)
zstd          830549     160099    0.193        305.4
>> this: hey br (-c 2 -z 60s)
this          830549     156779    0.189        244.7
>> ueffel: starting caddy-ueffel
>> ueffel: hey br (-c 2 -z 60s)
ueffel        830549     156753    0.189        139.0

LEVEL=3 ZLEVEL=default DURATION=60s FILE=nytimes.html ./bench.sh both

file: nytimes.html   br level: 3   zstd level: default   concurrency: 2   duration: 60s

encoder          raw compressed    ratio        req/s
-------          --- ----------    -----        -----
>> this: starting caddy-this
>> baseline: hey zstd (-c 2 -z 60s)
zstd         1049358     151502    0.144        392.6
>> this: hey br (-c 2 -z 60s)
this         1049358     136741    0.130        394.9
>> ueffel: starting caddy-ueffel
>> ueffel: hey br (-c 2 -z 60s)
ueffel       1049358     136595    0.130        191.4

LEVEL=3 ZLEVEL=default DURATION=60s FILE=wikipedia.html ./bench.sh both

file: wikipedia.html   br level: 3   zstd level: default   concurrency: 2   duration: 60s

encoder          raw compressed    ratio        req/s
-------          --- ----------    -----        -----
>> this: starting caddy-this
>> baseline: hey zstd (-c 2 -z 60s)
zstd         1058845     208819    0.197        283.3
>> this: hey br (-c 2 -z 60s)
this         1058845     200902    0.190        265.1
>> ueffel: starting caddy-ueffel
>> ueffel: hey br (-c 2 -z 60s)
ueffel       1058845     201231    0.190        139.4

LEVEL=3 ZLEVEL=default DURATION=60s FILE=mdn.html ./bench.sh both

file: mdn.html   br level: 3   zstd level: default   concurrency: 2   duration: 60s

encoder          raw compressed    ratio        req/s
-------          --- ----------    -----        -----
>> this: starting caddy-this
>> baseline: hey zstd (-c 2 -z 60s)
zstd          199970      29322    0.147       1698.2
>> this: hey br (-c 2 -z 60s)
this          199970      27650    0.138       1638.5
>> ueffel: starting caddy-ueffel
>> ueffel: hey br (-c 2 -z 60s)
ueffel        199970      27662    0.138        875.2
```
