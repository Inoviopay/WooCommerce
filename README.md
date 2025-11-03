# Inovio Payment Gateway for WooCommerce

A comprehensive WordPress plugin that integrates the Inovio payment processing platform with WooCommerce, supporting credit card payments, ACH transactions, and recurring subscriptions.

[![WordPress](https://img.shields.io/badge/WordPress-5.0%2B-blue.svg)](https://wordpress.org/)
[![WooCommerce](https://img.shields.io/badge/WooCommerce-3.0%2B-purple.svg)](https://woocommerce.com/)
[![PHP](https://img.shields.io/badge/PHP-5.2.4%2B-777BB4.svg)](https://www.php.net/)
[![License](https://img.shields.io/badge/License-GPLv2-green.svg)](https://www.gnu.org/licenses/gpl-2.0.html)

## Features

- **Credit Card Processing** - Accept Visa, MasterCard, American Express, Discover, and other major card brands
- **ACH Bank Payments** - Direct bank account debits via Automated Clearing House
- **Recurring Subscriptions** - Full integration with WooCommerce Subscriptions for automated recurring billing
- **Refund Management** - Process full and partial refunds directly from WooCommerce admin
- **Secure Tokenization** - PCI-compliant card tokenization through Inovio gateway
- **Affiliate Tracking** - Built-in support for affiliate parameter tracking
- **Terms of Service** - Customizable checkout checkboxes for legal compliance
- **Transaction Logging** - Debug mode for detailed transaction logging
- **Multi-Currency Support** - Works with WooCommerce multi-currency plugins

## Requirements

- **WordPress**: 5.0 or higher
- **WooCommerce**: 3.0 or higher
- **PHP**: 5.2.4 or higher
- **PHP Extensions**: cURL, JSON
- **SSL Certificate**: Required for production environments
- **Inovio Merchant Account**: Contact [Inovio Payments](https://www.inoviopay.com/) to open an account

## Installation

### Method 1: WordPress Admin Panel

1. Download the latest release ZIP file from the [releases page](../../releases)
2. Log in to your WordPress admin panel
3. Navigate to **Plugins > Add New**
4. Click **Upload Plugin** button
5. Select the `inovio-payment-gateway.zip` file
6. Click **Install Now**
7. After installation, click **Activate Plugin**

### Method 2: FTP Upload

1. Extract the `inovio-payment-gateway.zip` file
2. Upload the `inovio-payment-gateway` folder to `/wp-content/plugins/` directory via FTP
3. Log in to WordPress admin panel
4. Navigate to **Plugins**
5. Find **Inovio Payment Gateway** and click **Activate**

### Method 3: WP-CLI

```bash
wp plugin install inovio-payment-gateway.zip --activate
```

## Configuration

After activating the plugin:

1. Navigate to **WooCommerce > Settings > Payments**
2. You'll see two new payment methods:
   - **Inovio Credit Card Gateway**
   - **Inovio ACH Gateway**

### Credit Card Gateway Setup

1. Click **Manage** next to "Inovio Credit Card Gateway"
2. Configure the following settings:

| Setting | Description | Example |
|---------|-------------|---------|
| **Enable/Disable** | Enable Inovio credit card payments | ✓ Enabled |
| **Title** | Payment method name shown to customers | "Credit Card" |
| **Description** | Checkout page description | "Pay securely with your credit card" |
| **API Endpoint** | Inovio gateway URL | `https://gateway.inoviopay.com/payment/pmt_service.cfm` |
| **Site ID** | Your Inovio site identifier | `YOURSITE123` |
| **Username** | API authentication username | `api_user` |
| **Password** | API authentication password | `your_api_password` |
| **Product ID** | Inovio product identifier(s) | `PROD001` |
| **Debug Mode** | Enable transaction logging | ✓ for testing only |

3. Click **Save changes**

### ACH Gateway Setup

1. Click **Manage** next to "Inovio ACH Gateway"
2. Configure the same settings as credit card gateway
3. ACH-specific settings will be available for routing/account number collection

## WooCommerce Subscriptions Integration

If you have [WooCommerce Subscriptions](https://woocommerce.com/products/woocommerce-subscriptions/) installed:

1. The plugin automatically supports recurring payments
2. When a customer purchases a subscription product:
   - Initial payment is processed normally
   - Card/bank information is securely tokenized
   - Future recurring charges are processed automatically
3. Subscription management (pause, cancel, reactivate) is fully supported

## Usage

### Processing Payments

1. Customers select products and proceed to checkout
2. Choose **Inovio Credit Card** or **Inovio ACH** as payment method
3. Enter payment details in the secure form
4. Accept Terms of Service (automatically displayed)
5. For subscriptions, accept recurring billing disclosure
6. Click **Place Order**

### Processing Refunds

1. Navigate to **WooCommerce > Orders**
2. Select the order to refund
3. Scroll to **Order Items** section
4. Click **Refund** button
5. Enter refund amount
6. Click **Refund via Inovio**
7. The refund is processed automatically through the gateway

**Note**: Partial refunds are tracked in the database. The plugin calculates remaining refundable amount automatically.

### Viewing Transaction Details

Transaction information is stored in order meta:

1. Open any order in WooCommerce admin
2. View the **Order Notes** section for transaction logs
3. Custom fields visible in order details:
   - Transaction ID (`_inoviotransaction_id`)
   - Customer ID (`CUST_ID`)
   - Last 4 digits (`PMT_L4`)
   - Transaction status

## Affiliate Tracking

The plugin supports affiliate tracking via URL parameters:

```
https://yoursite.com/product-page/?affiliates=AFFILIATE123
```

The affiliate ID is stored in the customer session and included with the transaction.

## Debugging

### Enable Debug Mode

1. Go to payment gateway settings
2. Enable **Debug Mode**
3. Logs are written to: `wp-content/uploads/wc-logs/`

### View Logs

Navigate to **WooCommerce > Status > Logs** and select the Inovio log file.

**Warning**: Disable debug mode in production as logs may contain sensitive data.

## Security

- All payment data is transmitted over HTTPS
- Card numbers are never stored in WordPress database
- Tokenization handled by Inovio PCI-compliant gateway
- Input sanitization using WordPress/WooCommerce standards
- CSRF protection on all forms
- SQL injection prevention via prepared statements

## Database Tables

The plugin creates two custom tables on activation:

```sql
wp_inovio_refunded
  - id (Primary Key)
  - inovio_order_id
  - inovio_refunded_amount

wp_ach_inovio_refunded
  - id (Primary Key)
  - ach_inovio_order_id
  - ach_inovio_refunded_amount
```

Tables are automatically dropped on plugin deactivation.

## API Reference

### Payment Actions Supported

| Action | Description | Method |
|--------|-------------|--------|
| CCAUTHCAP | Authorize and capture credit card | `auth_and_capture()` |
| ACHAUTHCAP | Authorize and capture ACH payment | `ach_auth_and_capture()` |
| CCREVERSE | Void/refund credit card transaction | `ccreverse()` |
| ACHREVERSE | Reverse ACH transaction | `ach_reverse()` |
| CCAUTHORIZE | Authorize card only (no capture) | `authorization()` |
| CCCAPTURE | Capture previously authorized transaction | `capture()` |
| CCCREDIT | Issue credit to card | `cc_credit()` |
| TESTAUTH | Validate card details | `authenticate()` |
| TESTGW | Check gateway availability | `service_availability()` |

## Troubleshooting

### Common Issues

**Payment fails with "Invalid credentials" error**
- Verify API endpoint URL is correct
- Check Site ID, Username, and Password
- Ensure your Inovio account is active

**Subscriptions not processing automatically**
- Verify WooCommerce Subscriptions plugin is installed and active
- Check that initial payment was successful
- Review WooCommerce > Status > Logs for errors

**Refunds not working**
- Ensure transaction ID exists for the order
- Verify original payment was processed through Inovio
- Check API credentials have refund permissions

**SSL certificate errors**
- Ensure your server has up-to-date CA certificates
- Contact your hosting provider to update cURL/OpenSSL

## Support

- **Documentation**: See [DEVELOPER.md](./DEVELOPER.md) for technical details
- **Installation Guide**: See [INSTALLER.md](./INSTALLER.md) for detailed setup
- **Email Support**: clientsupport@inoviopay.com
- **Merchant Portal**: https://portal.inoviopay.com/

## Contributing

We welcome contributions! Please see [DEVELOPER.md](./DEVELOPER.md) for:
- Development setup instructions
- Code architecture overview
- Testing guidelines
- Pull request process

## Changelog

### Version 4.4.23 (2020-06-18)
- Added recurring payment/subscription functionality
- WooCommerce Subscriptions integration
- Subscription disclosure checkbox at checkout
- Improved refund tracking with custom database tables

### Previous Versions
See [releases](../../releases) for complete version history.

## License

This plugin is licensed under the GNU General Public License v2.0 or later.

See [LICENSE](https://www.gnu.org/licenses/gpl-2.0.html) for full license text.

## Credits

- **Author**: Inovio Payments
- **Website**: https://www.inoviopay.com/
- **Support**: clientsupport@inoviopay.com

---

**Note**: Merchants must have an active Inovio merchant account before using this plugin. New customers can request a merchant account through the [Inovio website](https://www.inoviopay.com/).
