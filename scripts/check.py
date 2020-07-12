import os
import sys
import logging
import pytz
import pandas as pd
import xml.etree.ElementTree as ET
from datetime import datetime
import glob
from typing import List, Tuple

LOGLEVEL = os.environ.get("LOGLEVEL", "INFO").upper()
logging.basicConfig(level=LOGLEVEL)


def check(file_path: str) -> Tuple[List[str], List[str]]:
    tree = ET.parse(file_path)
    root = tree.getroot()

    df_cols = ["start", "channel", "title"]
    df = pd.DataFrame(columns=df_cols)

    all_channels = list(
        map(
            lambda c: {
                "id": c.get("id"),
                "icon": c.find("icon").get("src").split("|")[0]
                if c.find("icon") is not None
                else "",
                "site": c.find("url").text,
            },
            root.findall("channel"),
        )
    )

    for i in root.iter("programme"):
        df = df.append(
            {
                "start": i.get("start"),
                "channel": i.get("channel"),
                "title": i.find("./title").text,
            },
            ignore_index=True,
        )
    df.set_index("start", inplace=True)
    df = df.set_index(pd.to_datetime(df.index))
    df.index = pd.to_datetime(df.index, utc=True)
    res = df[
        df.index.to_pydatetime()
        > (pytz.UTC.localize(datetime.utcnow() - pd.Timedelta(days=1)))
    ]
    count = res.groupby(["channel"], as_index=False).count()
    logging.debug(f"count: {count}")

    channels_with_no_prog = [
        x
        for x in set(map(lambda c: c["id"], all_channels))
        if x not in set(res["channel"].unique().tolist())
    ]

    return (all_channels, channels_with_no_prog)


if __name__ == "__main__":
    all: List[dict] = []
    missed: List[str] = []
    logging.debug(f"{datetime.today()}")
    try:
        for file_path in glob.glob(sys.argv[1] + "/*.xmltv"):
            logging.info(f"processing file {file_path}")
            all_ch, missed_ch = check(file_path)
            all = [*all, *all_ch]
            missed = [*missed, *missed_ch]
        df = pd.DataFrame(all, columns=["id", "icon", "site"])
        df["date"] = datetime.today()
        df.set_index("date", inplace=True)
        df["missed"] = df["id"].apply(lambda row: row in missed)
        logging.debug(df.head(10))
        logging.debug(f"all: {all}")
        logging.debug(f"with no progs: {missed}")
        logging.info(f"Total count: {len(all)} missed count: {len(missed)}")
        logging.info(f"Completness {100-(len(missed)/len(all)*100):3.2f}%")
        df.to_csv(
            os.path.join(sys.argv[1], "out", "epg.csv"),
            encoding="utf-8",
            date_format="%Y%m%d",
        )
    except Exception as ex:
        logging.error("Unexpected error:", ex)
        sys.exit(1)
