# PicoPiece--ATS_Center-Ats-fw-esp32-demo

This firmware exists solely to demonstrate automated hardware testing and is not intended to be a production product.

ats-fw-esp32-demo/
├── README.md
├── main/
│   ├── app_main.c
│   ├── gpio_demo.c
│   ├── oled_demo.c
│   └── ota.c
└── sdkconfig

ESP32 firmware is built on the Xeon server.
ATS nodes never build firmware.
They only consume signed/versioned artifacts for hardware validation.
