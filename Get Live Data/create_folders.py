import os
import datetime

now = datetime.datetime.now()


if now.month == 10:
    month = "oct"
else:
    month = "nov"

day = now.day
hour = now.hour
minute = now.minute
print(f"{month}{day}/{hour:02}/{minute:02}")

for month in ["oct", "nov"]:
    for day in range(1,5):
        for hour in range(24):
            for minute in range(60):
                pathname = f"{month}{day}/{hour:02}/{minute:02}"
                os.makedirs(pathname)


