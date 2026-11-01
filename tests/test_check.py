import importlib.util
import csv
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path


spec = importlib.util.spec_from_file_location("epg_check", Path(__file__).resolve().parents[1] / "scripts" / "check.py")
epg_check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(epg_check)


class CheckTests(unittest.TestCase):
    def test_mixed_timezones_and_missing_programmes(self):
        start = datetime.now(timezone.utc) + timedelta(days=1)
        utc = start.strftime("%Y%m%d%H%M%S +0000")
        other = start.astimezone(timezone(timedelta(hours=1))).strftime("%Y%m%d%H%M%S +0100")
        xml = f"""<tv>
          <channel id="one.fr"/><channel id="two.fr"/><channel id="missing.fr"/>
          <programme channel="one.fr" start="{utc}"><title>One</title></programme>
          <programme channel="two.fr" start="{other}"><title>Two</title></programme>
        </tv>"""
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "guide.xml"
            source.write_text(xml, encoding="utf-8")
            channels, missing = epg_check.check(str(source))
        self.assertEqual({channel["id"] for channel in channels}, {"one.fr", "two.fr", "missing.fr"})
        self.assertEqual(missing, ["missing.fr"])

    def test_generate_channel_and_statistics_files(self):
        start = (datetime.now(timezone.utc) + timedelta(days=1)).strftime("%Y%m%d%H%M%S +0000")
        xml = f"""<tv><channel id="one.fr"/><channel id="missing.fr"/>
          <programme channel="one.fr" start="{start}"><title>One</title></programme>
        </tv>"""
        scripts = Path(__file__).resolve().parents[1] / "scripts"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "out").mkdir()
            (root / "guide.xml").write_text(xml, encoding="utf-8")
            subprocess.run([sys.executable, str(scripts / "check.py"), str(root)], cwd=root, check=True)
            subprocess.run([sys.executable, str(scripts / "stats_epg.py"), "-s", "-f", "out/epg.csv"], cwd=root, check=True)
            with (root / "out" / "epg_stats.csv").open(encoding="utf-8", newline="") as stream:
                channels = {row["id"]: row for row in csv.DictReader(stream)}
        self.assertEqual(channels["one.fr"]["missed_percent"], "0.0")
        self.assertEqual(channels["missing.fr"]["missed_percent"], "100.0")


if __name__ == "__main__":
    unittest.main()
