import importlib
import sys
import types
import unittest


class FakeSpatialReference:
    def __init__(self):
        self.axis_mapping_strategy = None

    def SetAxisMappingStrategy(self, strategy):
        self.axis_mapping_strategy = strategy


class GDALAxisOrderTests(unittest.TestCase):
    def test_forces_traditional_gis_axis_order_when_available(self):
        fake_osgeo = types.ModuleType("osgeo")
        fake_osr = types.ModuleType("osgeo.osr")
        fake_osr.OAMS_TRADITIONAL_GIS_ORDER = "traditional"
        fake_osgeo.gdal = types.ModuleType("osgeo.gdal")
        fake_osgeo.osr = fake_osr
        fake_rtree = types.ModuleType("rtree")
        fake_rtree_index = types.ModuleType("rtree.index")
        fake_rtree.index = fake_rtree_index

        old_modules = {
            name: sys.modules.get(name)
            for name in (
                "osgeo",
                "osgeo.gdal",
                "osgeo.osr",
                "rtree",
                "rtree.index",
                "gdal_interfaces",
            )
        }
        sys.modules["osgeo"] = fake_osgeo
        sys.modules["osgeo.gdal"] = fake_osgeo.gdal
        sys.modules["osgeo.osr"] = fake_osr
        sys.modules["rtree"] = fake_rtree
        sys.modules["rtree.index"] = fake_rtree_index
        sys.modules.pop("gdal_interfaces", None)

        try:
            gdal_interfaces = importlib.import_module("gdal_interfaces")
            spatial_reference = FakeSpatialReference()

            gdal_interfaces.use_traditional_axis_order(spatial_reference)

            self.assertEqual(spatial_reference.axis_mapping_strategy, "traditional")
        finally:
            for name, module in old_modules.items():
                if module is None:
                    sys.modules.pop(name, None)
                else:
                    sys.modules[name] = module


if __name__ == "__main__":
    unittest.main()
