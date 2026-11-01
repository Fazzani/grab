import importlib.util
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


if __name__ == "__main__":
    unittest.main()
