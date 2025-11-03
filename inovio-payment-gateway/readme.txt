=== Inovio Payment Gateway WooCommerce Plugin ===
Contributors: inoviopay
Plugin Name: Inovio Payment Gateway WooCommerce Plugin
Description: Inovio Payment Gateway WooCommerce Plugin
Author: Inovio Payments
Version: 5.1.0
Author URI: https://inoviopay.com/
Plugin URI: https://www.inoviopay.com
License: GPLv2
License URI: https://www.gnu.org/licenses/gpl-2.0.html
Text Domain: wporg
Domain Path: /languages
Requires at least: 6.0
Tested up to: 6.4
Requires PHP: 7.4
WC requires at least: 7.0
WC tested up to: 10.3
Stable tag: 5.3.0

== Description ==
The future of online selling is here. Inovio is a fully-integrated, global payments platform for ecommerce merchant. Reliable and secure, our innovative payment processing platform offers a seamless merchant experience for credit card transactions, US ACH, US and EU direct debit, worldwide SMS, and electronic cash payments. Based on anything from issuer to currency, our intelligent transaction routing maximizes approvals and reduces downgraded transactions and surcharges. Get instant update notifications from every major network for up-to-date cardholder information.
Inovio’s WooCommerce plugin is open source, safe and secure for our Merchants. The plugin supports recurring payment through the Subscription plugin found in WooCommerce. 
Merchants must have an account with Inovio before they can start using the plugin. New customers can request a Merchant Account through our website at https://www.inoviopay.com/.

== Installation ==
Process 1
----------------
1- Login to wordpress admin panel and go to Dashboard plugins option.
2- Click on Plugins -> Add New.
3- Select woocommerce-inovio-gateway.zip file and upload it.
4- Activate plugin after installing woocommerce inovio gateway.
5- Now you can see plugin features by navigating through WooCommerce->Settings->Checkout. Alternatively, after activating plugin, you can click Settings link to enter into checkout tab.

Process 2
-----------------
1- Add woocommerce-inovio-gateway folder into wp-content/plugins folder.
2- Login into wordpress dashboard and click on plugins.
3- Now you can see Inovio Payment Gateway plugin in plugins section.
4- In order to see plugin features, you will need to activate the plugin.
5- Now you can see plugin features by navigating through WooCommerce->Settings->Checkout. Alternatively, after activating plugin, you can click Settings link to enter into checkout tab.

== Screenshots ==
1. Inovio Payment Methods
2. Inovio credit card payment method
3. Inovio ACH payment method

== Support ==
Get answers on pricing, feature implementation, API integration, and more... at clientsupport@inoviopay.com

== Changelog ==
= 5.1.0 - 2025-01-03 =
* Major Update: Full WooCommerce 10.x and HPOS (High-Performance Order Storage) compatibility
* Fixed: Replaced deprecated $order->id with $order->get_id() for HPOS compatibility
* Fixed: Replaced all post meta functions with WooCommerce CRUD methods
* Fixed: SQL injection vulnerability in ACH refund query
* Fixed: Replaced deprecated woocommerce_clean() with wc_clean()
* Fixed: Replaced deprecated reduce_order_stock() with wc_reduce_stock_levels()
* Fixed: Removed legacy WooCommerce 2.0 version checks
* Improved: Changed database engine from MyISAM to InnoDB
* Improved: Added proper database indexes for better performance
* Updated: Minimum requirements - WordPress 6.0+, WooCommerce 7.0+, PHP 7.4+
* Declared: Official HPOS/Custom Order Tables compatibility

= 4.4.23 - 2020-06-18 =
* Added: Recurring payment/subscription functionality