# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is the **Inovio Payment Gateway WooCommerce Plugin** - a WordPress plugin that integrates the Inovio payment processing platform with WooCommerce. The plugin supports:

- Credit card payments via Inovio direct gateway
- ACH (Automated Clearing House) bank payments
- WooCommerce Subscriptions integration for recurring payments
- Full refund capabilities (partial and complete)
- Terms of Service and subscription disclosure checkboxes at checkout
- Affiliate tracking via URL parameters

**Version**: 4.4.23
**WordPress**: Requires 5.0+, tested to 5.5
**PHP**: Requires 5.2.4+

## Architecture Structure

### Core Payment Gateway Classes

The plugin follows WordPress/WooCommerce plugin architecture with two parallel payment methods:

1. **Credit Card Gateway** (`inoviodirectmethod`)
   - Main class: `Woocommerce_Inovio_Gateway` extends `Inovio_Direct_Method` extends `WC_Payment_Gateway`
   - Location: `includes/inoviopay/woocommerce-inovio-gateway.php`
   - Payment form: Uses shortcode `[direct_checkoutform]` rendered at checkout

2. **ACH Gateway** (`achinoviomethod`)
   - Main class: `Woocommerce_Ach_Inovio_Gateway` extends `Ach_Inovio_Method` extends `WC_Payment_Gateway`
   - Location: `includes/ach/class-woocommerce-ach-inovio-gateway.php`
   - Payment form: Uses shortcode `[ach_checkoutform]` rendered at checkout

### Inovio Core API Layer

Located in `includes/common/inovio-core/`, these classes abstract the payment gateway communication:

- **InovioServiceConfig**: Configures API endpoints and credentials, assembles request parameters
- **InovioProcessor**: Processes payment actions by calling specific request methods
- **InovioConnection**: Handles cURL-based HTTP communication with SSL support

### Payment Flow

```
Customer Checkout
    ↓
WC_Payment_Gateway::process_payment()
    ↓
class_common_inovio_payment::get_order_params() [assembles order data]
    ↓
InovioServiceConfig [configuration]
    ↓
InovioProcessor::set_methodname() [auth_and_capture, ccreverse, etc.]
    ↓
InovioConnection [cURL to Inovio API]
    ↓
Response parsed and order updated
```

### Supported Payment Actions

Via `InovioProcessor` methods:
- `auth_and_capture()` - CCAUTHCAP: Authorize and capture credit card payment
- `ach_auth_and_capture()` - ACHAUTHCAP: Process ACH payment
- `ccreverse()` - CCREVERSE: Refund credit card transaction
- `ach_reverse()` - ACHREVERSE: Reverse ACH transaction
- `authorization()` - CCAUTHORIZE: Pre-authorize card only
- `capture()` - CCCAPTURE: Capture a previous authorization
- `cc_credit()` - CCCREDIT: Issue credit
- `authenticate()` - TESTAUTH: Validate card details
- `service_availability()` - TESTGW: Check gateway availability

## Database Schema

The plugin creates custom tables for tracking refunds:

```sql
{prefix}inovio_refunded
  - id (bigint, primary key)
  - inovio_order_id (bigint)
  - inovio_refunded_amount (varchar 256)

{prefix}ach_inovio_refunded
  - id (bigint, primary key)
  - ach_inovio_order_id (bigint)
  - ach_inovio_refunded_amount (varchar 256)
```

Tables are created on plugin activation via `includes/installer/inovio-plugin-database-table.php`.

## WordPress/WooCommerce Integration Points

### Hooks Used by Plugin

- `plugins_loaded` - Initialize payment gateway classes
- `woocommerce_payment_gateways` - Register Inovio gateways with WooCommerce
- `woocommerce_update_options_payment_gateways_{gateway_id}` - Save admin settings
- `woocommerce_review_order_before_submit` - Add Terms of Service and subscription disclosure checkboxes
- `woocommerce_checkout_update_order_meta` - Save checkbox state to order meta
- `woocommerce_admin_order_data_after_billing_address` - Display checkbox status in admin
- `woocommerce_scheduled_subscription_payment_{gateway_id}` - Process recurring subscription payments
- `register_activation_hook` - Create database tables
- `register_deactivation_hook` - Drop database tables

### Custom Order Meta Fields

Stored via `update_post_meta()` on each transaction:
- `_inoviotransaction_id` - Inovio PO_ID (transaction identifier)
- `_inovio_gateway_scheduled_request` - JSON of subscription payment request params
- `_inovio_gateway_scheduled_response` - JSON of subscription payment response
- `_inovio_gateway_scheduled_first_request` - JSON of initial payment request
- `_inovio_gateway_scheduled_first_response` - JSON of initial payment response
- `CUST_ID`, `PMT_L4`, `REQ_ID`, `TRANS_STATUS_NAME`, `TRANS_ID` - Individual transaction fields
- `my_field_name` - Subscription renewal checkbox state
- `my_field_term` - Terms of Service checkbox state

## Configuration Requirements

Merchants must configure the following in WooCommerce > Settings > Checkout:

- **API Endpoint** - Inovio payment gateway URL (typically https://gateway.inoviopay.com/payment/pmt_service.cfm)
- **Site ID** - Merchant's Inovio site identifier
- **Username** - Request authentication username
- **Password** - Request authentication password
- **Product ID** - Inovio product identifier(s)
- **Debug Mode** - Enable logging to WooCommerce logs

## Development Patterns

### Adding New Payment Methods

To add a new payment method type:
1. Create a new method class extending `WC_Payment_Gateway` in `includes/{method-name}/`
2. Create the gateway configuration class in `includes/{method-name}/class-woocommerce-{method}-inovio-gateway.php`
3. Include the new gateway file in main plugin file `woocommerce-inovio-gateway.php`
4. Register the gateway using `add_filter('woocommerce_payment_gateways', callback)`
5. Create payment form shortcode in `includes/common/shortcodes/class-inovio-payment-shortcodes.php`

### Processing Transactions

Transaction processing follows this pattern:
```php
$params = array_merge(
    $this->common_class->merchant_credential($this),
    $this->common_class->get_order_params($order_id, $post_data, $expiry),
    $this->common_class->get_product_ids($order, $this)
);

$service_config = new InovioServiceConfig($params);
$processor = new InovioProcessor($service_config);
$response = $processor->set_methodname('auth_and_capture')->get_response();
$result = json_decode($response);
```

### Subscription Payments

Recurring payments are handled via `scheduled_subscription_payment($amount, $order)`:
- Retrieves stored customer/card token from initial order
- Constructs payment request with subscription-specific params
- Uses `SSPI_DONE` constant to prevent duplicate processing
- Stores request/response in order meta for debugging

### Refund Handling

Partial refunds are tracked in custom database tables to calculate remaining refundable amount:
```php
$amount = $order->get_total() - $this->inovio_get_total_refunded($order_id);
```

Full refunds are processed via `process_refund()` which calls the `ccreverse` API method.

## Security Considerations

- Card numbers are sanitized: `str_replace(array(' ', '-'), '', wc_clean($_POST['card_number']))`
- All POST data is sanitized via `wc_clean()`
- Expiry dates are validated via `validate_expirydate()`
- SSL verification can be disabled in `InovioConnection` (not recommended for production)
- API credentials are stored in WooCommerce settings (encrypted by WordPress)
- Transaction responses are logged only when debug mode is enabled

## Connection to Main Inovio System

This WooCommerce plugin is a **shopping cart integration** that connects to the core Inovio ArgusPay payment gateway (described in the parent CLAUDE.md). The plugin:

- Sends payment requests to the ColdFusion-based payment gateway endpoints (typically `/payment/pmt_service.cfm`)
- Uses the same API request parameters (`request_action`, `request_client_id`, etc.) as other integrations
- Receives standardized JSON responses with fields like `PO_ID`, `TRANS_STATUS_NAME`, `CUST_ID`
- Relies on the backend Oracle/PL/SQL processing for actual payment authorization and settlement

The plugin is part of the broader Inovio payment ecosystem which includes 80+ payment processor integrations managed by the central gateway.

## File Structure

```
inovio-payment-gateway/
├── woocommerce-inovio-gateway.php          # Main plugin file
├── readme.txt                               # WordPress plugin repository readme
├── includes/
│   ├── inoviopay/
│   │   ├── woocommerce-inovio-gateway.php  # Credit card gateway registration
│   │   └── methods/
│   │       └── class-inovio-direct-method.php  # Credit card payment logic
│   ├── ach/
│   │   ├── class-woocommerce-ach-inovio-gateway.php  # ACH gateway registration
│   │   └── methods/
│   │       └── class-ach-inovio-method.php  # ACH payment logic
│   ├── common/
│   │   ├── class-common-inovio-payment.php  # Shared utilities
│   │   ├── inovio-core/
│   │   │   ├── class-inovioserviceconfig.php  # API configuration
│   │   │   ├── class-inovioprocessor.php      # Payment processing
│   │   │   └── class-inovioconnection.php     # HTTP communication
│   │   └── shortcodes/
│   │       └── class-inovio-payment-shortcodes.php  # Admin forms and checkout forms
│   └── installer/
│       └── inovio-plugin-database-table.php  # Database table creation/deletion
└── assets/
    ├── css/
    │   └── inovio-style.css
    ├── js/
    │   ├── inovio-script.js
    │   └── inovio-ach-script.js
    ├── img/
    │   └── [payment method logos]
    └── pdf/
        └── TOS_ENG.pdf                      # Terms of Service document
```
