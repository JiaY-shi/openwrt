# RTL8372N DSA switch driver

This package builds the RTL8372N DSA driver from:

https://github.com/airjinkela/rtl837x-dsa-driver

The source revision and archive hash are pinned in `Makefile`. OpenWrt-specific
fixes are kept in `patches/`.

## Package contents

The package name is `kmod-rtl837x-dsa`. It contains:

- `rtl8372n_dsa.ko`, the switch and internal PHY driver;
- `tag_vsc73xx_8021q.ko`, the DSA tagger used by Qualcomm PPE offload.

The VSC73xx 802.1Q tag protocol is the default. The driver also retains its
RTL8_4 tag implementation, but that protocol does not provide the tag_8021q
metadata used by the Qualcomm PPE integration.

## Device tree

Use `realtek,rtl8372n`, a DSA `ports` node, and explicit Clause 45 PHY nodes.
The GL-BE6500 definition in
`target/linux/qualcommbe/dts/ipq5332-gl-be6500.dts` is the reference.

```dts
switch@29 {
	compatible = "realtek,rtl8372n";
	reg = <29>;
	#address-cells = <1>;
	#size-cells = <0>;

	ports {
		#address-cells = <1>;
		#size-cells = <0>;

		port@3 {
			reg = <3>;
			label = "cpu";
			ethernet = <&gmac2>;
			phy-mode = "10gbase-r";

			fixed-link {
				speed = <10000>;
				full-duplex;
			};
		};

		port@4 {
			reg = <4>;
			label = "lan1";
			phy-mode = "internal";
			phy-handle = <&switch_phy4>;
		};
	};

	mdio {
		#address-cells = <1>;
		#size-cells = <0>;

		switch_phy4: ethernet-phy@4 {
			compatible = "ethernet-phy-ieee802.3-c45";
			reg = <4>;
		};
	};
};
```

Optional board properties supported by the driver include `reset-gpios`,
SerDes RX/TX polarity swaps, PHY MDI reversal, PHY TX polarity swap, and the
switch GPIO controller.

## Implemented DSA behavior

- bridge join and leave with hardware port isolation;
- STP state programming across every FID;
- VLAN filtering, PVID, tagged and untagged membership;
- tag_8021q standalone and bridge VIDs;
- static FDB and MDB programming;
- hardware ageing time and MIB/pause counters;
- BPDU trapping to the CPU;
- phylink and internal 2.5G PHY support.

OpenWrt should add the DSA user ports directly to bridges. Do not configure the
switch with `swconfig` or `switch_vlan`.

PPE acceleration must be verified on hardware for routed IPv4/IPv6, bridged
traffic, and VLAN devices. Driver compilation alone does not prove that every
flow is accepted by the PPE classifier.
