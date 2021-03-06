/*
 * leds-msm-kb.c - MSM Qwerty keypad LEDs driver.
 *
 * Copyright (c) 2009, Code Aurora Forum. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/leds.h>

#include <mach/pmic.h>
#include <linux/gpio.h>
#include <mach/msm8960-gpio.h>

static void msm_keypad_bl_led_set(struct led_classdev *led_cdev,
	enum led_brightness value)
{
	int gpio = *(int *)(led_cdev->dev->parent->platform_data);
	if (value)
		gpio_direction_output(gpio, 1);
	else
		gpio_direction_output(gpio, 0);
	printk(KERN_INFO "[KBLED] set value: %d\n",
			gpio_get_value(gpio));
}

static struct led_classdev msm_kb_bl_led = {
	.name			= "keyboard-backlight",
	.brightness_set		= msm_keypad_bl_led_set,
	.brightness		= LED_OFF,
};
static int msm_kb_led_probe(struct platform_device *pdev)
{
	int rc;

	rc = led_classdev_register(&pdev->dev, &msm_kb_bl_led);
	if (rc) {
		dev_err(&pdev->dev, "unable to register led class driver\n");
		return rc;
	}
	msm_keypad_bl_led_set(&msm_kb_bl_led, LED_OFF);
	return rc;
}

static int __devexit msm_kb_led_remove(struct platform_device *pdev)
{
	led_classdev_unregister(&msm_kb_bl_led);

	return 0;
}

#ifdef CONFIG_PM
static int msm_kb_led_suspend(struct platform_device *dev,
		pm_message_t state)
{
	led_classdev_suspend(&msm_kb_bl_led);

	return 0;
}

static int msm_kb_led_resume(struct platform_device *dev)
{
	led_classdev_resume(&msm_kb_bl_led);

	return 0;
}
#else
#define msm_kb_led_suspend NULL
#define msm_kb_led_resume NULL
#endif

static struct platform_driver msm_kb_led_driver = {
	.probe		= msm_kb_led_probe,
	.remove		= __devexit_p(msm_kb_led_remove),
	.suspend	= msm_kb_led_suspend,
	.resume		= msm_kb_led_resume,
	.driver		= {
		.name	= "kb-leds",
		.owner	= THIS_MODULE,
	},
};

static int __init msm_kb_led_init(void)
{
	return platform_driver_register(&msm_kb_led_driver);
}
module_init(msm_kb_led_init);

static void __exit msm_kb_led_exit(void)
{
	platform_driver_unregister(&msm_kb_led_driver);
}
module_exit(msm_kb_led_exit);

MODULE_DESCRIPTION("MSM KB LEDs driver");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:kb-leds");
