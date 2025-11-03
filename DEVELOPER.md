# Inovio Payment Gateway - Developer Documentation

Technical documentation for developers, maintainers, and contributors.

## Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Architecture Overview](#architecture-overview)
- [Code Structure](#code-structure)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Debugging](#debugging)
- [Contributing](#contributing)
- [Release Process](#release-process)

## Development Environment Setup

### Prerequisites

```bash
# Required software
- PHP 7.4+ (for development, production supports 5.2.4+)
- MySQL 5.7+ or MariaDB 10.3+
- WordPress 5.5+
- WooCommerce 4.0+
- Composer (optional, for dependency management)
- Git
- Node.js 14+ (if working with assets)
```

### Local Development Setup

**Option 1: Local by Flywheel (Recommended)**

1. Install [Local by Flywheel](https://localwp.com/)
2. Create new WordPress site:
   - PHP Version: 7.4
   - WordPress: Latest
3. Install WooCommerce plugin
4. Clone this repository into plugins directory:
   ```bash
   cd ~/Local Sites/your-site/app/public/wp-content/plugins/
   git clone [repository-url] inovio-payment-gateway
   ```

**Option 2: Docker Development Environment**

```bash
# Clone repository
git clone [repository-url] inovio-payment-gateway
cd inovio-payment-gateway

# Create docker-compose.yml for WordPress
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - ./:/var/www/html/wp-content/plugins/inovio-payment-gateway
  db:
    image: mysql:5.7
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_ROOT_PASSWORD: root
EOF

# Start environment
docker-compose up -d
```

**Option 3: XAMPP/MAMP/WAMP**

1. Install local server stack
2. Create WordPress installation
3. Clone plugin to `wp-content/plugins/inovio-payment-gateway`
4. Activate plugin in WordPress admin

### Install Development Dependencies

```bash
cd inovio-payment-gateway

# If using Composer (future enhancement)
composer install --dev

# If working with JavaScript/CSS
npm install
```

### Configure Test Environment

**Create wp-config-local.php for local settings:**

```php
<?php
// Local development configuration
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', true);
define('SCRIPT_DEBUG', true);

// Inovio test credentials
define('INOVIO_TEST_ENDPOINT', 'https://gateway-test.inoviopay.com/payment/pmt_service.cfm');
define('INOVIO_TEST_SITE_ID', 'TESTBANK');
define('INOVIO_TEST_USERNAME', 'test_user');
define('INOVIO_TEST_PASSWORD', 'test_password');
```

## Architecture Overview

### Class Hierarchy

```
WC_Payment_Gateway (WooCommerce Core)
    ├── Inovio_Direct_Method
    │   └── Woocommerce_Inovio_Gateway (Credit Card)
    │
    └── Ach_Inovio_Method
        └── Woocommerce_Ach_Inovio_Gateway (ACH)
```

### Core Components

#### 1. Gateway Registration Classes

**Purpose**: Register payment methods with WooCommerce

```php
// Credit Card: includes/inoviopay/woocommerce-inovio-gateway.php
class Woocommerce_Inovio_Gateway extends Inovio_Direct_Method

// ACH: includes/ach/class-woocommerce-ach-inovio-gateway.php
class Woocommerce_Ach_Inovio_Gateway extends Ach_Inovio_Method
```

#### 2. Payment Method Classes

**Purpose**: Core payment processing logic

```php
// Credit Card: includes/inoviopay/methods/class-inovio-direct-method.php
class Inovio_Direct_Method extends WC_Payment_Gateway
    - process_payment($order_id)
    - process_refund($order_id, $amount, $reason)
    - scheduled_subscription_payment($amount, $order)

// ACH: includes/ach/methods/class-ach-inovio-method.php
class Ach_Inovio_Method extends WC_Payment_Gateway
    - Similar methods adapted for ACH
```

#### 3. Inovio Core API Layer

**Purpose**: Abstract payment gateway communication

```php
// Configuration: includes/common/inovio-core/class-inovioserviceconfig.php
class InovioServiceConfig
    - get_config()          // Returns API configuration
    - execute_call($params) // Executes HTTP request
    - filter_response()     // Parses response

// Processor: includes/common/inovio-core/class-inovioprocessor.php
class InovioProcessor
    - set_methodname($method)  // Set request action
    - get_response()           // Execute and return response
    - auth_and_capture()       // CCAUTHCAP
    - ccreverse()              // CCREVERSE
    - ach_auth_and_capture()   // ACHAUTHCAP
    // ... more methods

// Connection: includes/common/inovio-core/class-inovioconnection.php
class InovioConnection
    - set_requesturl($url)
    - set_http_method($method)
    - set_postfields($data)
    // cURL wrapper with SSL support
```

#### 4. Utility Classes

```php
// Common utilities: includes/common/class-common-inovio-payment.php
class class_common_inovio_payment
    - merchant_credential($gateway)
    - get_order_params($order_id, $post_data, $expiry)
    - get_product_ids($order, $gateway)
    - validate_expirydate($expiry)
    - merchant_authorization($gateway)
    - restrict_quantity($gateway)
    - inovio_logger($message, $gateway)

// Shortcodes: includes/common/shortcodes/class-inovio-payment-shortcodes.php
class inovio_payment_shortcodes
    - inovio_admin_setting_form($type)
    - direct_checkoutform()    // [direct_checkoutform]
    - ach_checkoutform()       // [ach_checkoutform]
```

### Payment Processing Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Customer submits checkout form                          │
│    POST data: card number, expiry, CVV, billing info       │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Inovio_Direct_Method::process_payment($order_id)        │
│    - Validate card number, expiry, CVV                      │
│    - Sanitize all POST data via wc_clean()                  │
│    - Check merchant authorization                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. class_common_inovio_payment::get_order_params()         │
│    - Extract order details (amount, customer, billing)      │
│    - Extract card details from POST                         │
│    - Build parameter array                                  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. InovioServiceConfig::__construct($params)               │
│    - Merge merchant credentials                             │
│    - Merge order parameters                                 │
│    - Merge product IDs                                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. InovioProcessor::set_methodname('auth_and_capture')     │
│    - Sets request_action = 'CCAUTHCAP'                      │
│    - Returns $this for chaining                             │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. InovioProcessor::get_response()                         │
│    - Calls private auth_and_capture() method                │
│    - Executes InovioServiceConfig::execute_call()          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. InovioConnection (via ServiceConfig)                    │
│    - Build cURL request to API endpoint                     │
│    - POST parameters to Inovio gateway                      │
│    - Return JSON response                                   │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Parse Response                                           │
│    $result = json_decode($response)                         │
│    - Check $result->TRANS_STATUS_NAME == 'APPROVED'        │
│    - Store $result->PO_ID as transaction ID                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. Complete Order                                           │
│    - $order->payment_complete($result->PO_ID)              │
│    - update_post_meta with transaction details              │
│    - Redirect to thank you page                             │
└─────────────────────────────────────────────────────────────┘
```

### Database Schema

**Refund Tracking Tables:**

```sql
CREATE TABLE wp_inovio_refunded (
    id BIGINT(20) NOT NULL AUTO_INCREMENT,
    inovio_order_id BIGINT(20) NOT NULL,
    inovio_refunded_amount VARCHAR(256),
    PRIMARY KEY (id),
    INDEX idx_order_id (inovio_order_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE wp_ach_inovio_refunded (
    id BIGINT(20) NOT NULL AUTO_INCREMENT,
    ach_inovio_order_id BIGINT(20) NOT NULL,
    ach_inovio_refunded_amount VARCHAR(256),
    PRIMARY KEY (id),
    INDEX idx_order_id (ach_inovio_order_id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
```

**Order Meta Keys:**

```php
// Transaction details
'_inoviotransaction_id'     // Inovio PO_ID
'CUST_ID'                    // Customer ID from Inovio
'PMT_L4'                     // Last 4 digits of card
'REQ_ID'                     // Request ID
'TRANS_STATUS_NAME'          // Transaction status
'TRANS_ID'                   // Internal transaction ID

// Subscription data (for WooCommerce Subscriptions)
'_inovio_gateway_scheduled_request'       // JSON: subscription renewal request
'_inovio_gateway_scheduled_response'      // JSON: subscription renewal response
'_inovio_gateway_scheduled_first_request' // JSON: initial payment request
'_inovio_gateway_scheduled_first_response'// JSON: initial payment response

// Checkout checkboxes
'my_field_term'              // Terms of Service acceptance
'my_field_name'              // Subscription disclosure acceptance
```

## Code Structure

### Directory Layout

```
inovio-payment-gateway/
│
├── woocommerce-inovio-gateway.php    # Main plugin file, hooks, activation
├── readme.txt                         # WordPress.org plugin readme
│
├── includes/
│   ├── installer/
│   │   └── inovio-plugin-database-table.php  # DB table creation/deletion
│   │
│   ├── common/
│   │   ├── class-common-inovio-payment.php   # Shared utilities
│   │   ├── inovio-core/
│   │   │   ├── class-inovioserviceconfig.php # API config
│   │   │   ├── class-inovioprocessor.php     # Payment processor
│   │   │   └── class-inovioconnection.php    # HTTP/cURL wrapper
│   │   └── shortcodes/
│   │       └── class-inovio-payment-shortcodes.php  # Forms & shortcodes
│   │
│   ├── inoviopay/                     # Credit card gateway
│   │   ├── woocommerce-inovio-gateway.php    # Registration
│   │   └── methods/
│   │       └── class-inovio-direct-method.php # Payment logic
│   │
│   └── ach/                           # ACH gateway
│       ├── class-woocommerce-ach-inovio-gateway.php  # Registration
│       └── methods/
│           └── class-ach-inovio-method.php    # ACH payment logic
│
└── assets/
    ├── css/
    │   └── inovio-style.css           # Plugin styles
    ├── js/
    │   ├── inovio-script.js           # Credit card form scripts
    │   └── inovio-ach-script.js       # ACH form scripts
    ├── img/
    │   ├── inovio-logo.png
    │   └── [payment logos]
    └── pdf/
        └── TOS_ENG.pdf                # Terms of Service
```

### Coding Standards

**Follow WordPress Coding Standards:**

```bash
# Install PHP_CodeSniffer
composer global require "squizlabs/php_codesniffer=*"

# Install WordPress standards
composer global require wp-coding-standards/wpcs

# Configure
phpcs --config-set installed_paths /path/to/wpcs

# Check code
phpcs --standard=WordPress includes/

# Auto-fix issues
phpcbf --standard=WordPress includes/
```

**Key Standards:**

1. **Naming Conventions:**
   ```php
   class Class_Name {}                // Classes: Capitalized_With_Underscores
   function function_name() {}        // Functions: lowercase_with_underscores
   $variable_name                     // Variables: lowercase_with_underscores
   CONSTANT_NAME                      // Constants: UPPERCASE_WITH_UNDERSCORES
   ```

2. **File Headers:**
   ```php
   <?php
   /**
    * File description
    *
    * @package Inovio
    * @since 4.4.23
    */
   ```

3. **Function Documentation:**
   ```php
   /**
    * Process payment for order
    *
    * @param int $order_id WooCommerce order ID
    * @return array Result with 'success' or 'error'
    */
   public function process_payment( $order_id ) {
       // Implementation
   }
   ```

4. **Security:**
   ```php
   // Always sanitize input
   $card_number = wc_clean( $_POST['card_number'] );

   // Always escape output
   echo esc_html( $message );

   // Use nonces for forms
   wp_nonce_field( 'inovio_payment', 'inovio_nonce' );

   // Validate nonces
   if ( ! wp_verify_nonce( $_POST['inovio_nonce'], 'inovio_payment' ) ) {
       die( 'Security check failed' );
   }
   ```

## Development Workflow

### Setting Up Feature Branch

```bash
# Clone repository
git clone [repository-url]
cd inovio-payment-gateway

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
# ... edit files ...

# Commit with descriptive message
git add .
git commit -m "Add support for new payment action"

# Push to remote
git push origin feature/your-feature-name
```

### Making Changes

**Adding a New Payment Method:**

1. Create processor method in `class-inovioprocessor.php`:
   ```php
   private function new_payment_action() {
       $this->requestparams['request_action'] = 'NEWACTION';
       $response = $this->service_config->execute_call( $this->requestparams );
       return $this->service_config->filter_response( $response, [] );
   }
   ```

2. Add public method in payment class:
   ```php
   public function process_new_action( $order_id ) {
       $params = $this->common_class->merchant_credential( $this );
       $service_config = new InovioServiceConfig( $params );
       $processor = new InovioProcessor( $service_config );
       $response = $processor->set_methodname( 'new_payment_action' )->get_response();
       return json_decode( $response );
   }
   ```

3. Add tests (see Testing section)

**Adding a New Settings Field:**

1. Edit shortcodes class `class-inovio-payment-shortcodes.php`:
   ```php
   public function inovio_admin_setting_form( $type ) {
       $form_fields = array(
           // ... existing fields ...
           'new_setting' => array(
               'title'       => __( 'New Setting' ),
               'type'        => 'text',
               'description' => __( 'Description of new setting' ),
               'default'     => '',
               'desc_tip'    => true,
           ),
       );
       return $form_fields;
   }
   ```

2. Access in payment method:
   ```php
   $this->new_setting = $this->get_option( 'new_setting' );
   ```

## Testing

### Manual Testing

**Test Checklist:**

- [ ] Fresh WordPress installation (5.0+)
- [ ] WooCommerce installed (3.0+)
- [ ] Plugin activates without errors
- [ ] Database tables created
- [ ] Payment methods appear in WooCommerce > Payments
- [ ] Settings save correctly
- [ ] Checkout form displays properly
- [ ] Test card transaction succeeds
- [ ] Transaction ID stored in order meta
- [ ] Refund processes correctly
- [ ] Partial refund calculated properly
- [ ] Subscription initial payment works (with WC Subscriptions)
- [ ] Subscription renewal processes automatically
- [ ] Debug logs written when enabled
- [ ] Plugin deactivates cleanly
- [ ] Database tables dropped on deactivation

### Automated Testing (Future Enhancement)

**PHPUnit Tests:**

```bash
# Install PHPUnit
composer require --dev phpunit/phpunit

# Create test file: tests/test-inovio-processor.php
<?php
class Test_Inovio_Processor extends WP_UnitTestCase {
    public function test_auth_and_capture() {
        // Test implementation
    }
}

# Run tests
./vendor/bin/phpunit
```

### Test Cards

| Scenario | Card Number | Expiry | CVV |
|----------|-------------|--------|-----|
| Successful auth | 4111111111111111 | 12/25 | 123 |
| Declined | 4000000000000002 | 12/25 | 123 |
| Invalid card number | 4111111111111112 | 12/25 | 123 |
| Expired card | 4111111111111111 | 12/20 | 123 |

## Debugging

### Enable Debug Mode

```php
// In wp-config.php
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );

// Enable Inovio debug in payment settings
$this->debug = 'yes';
```

### Log Locations

```bash
# WordPress debug log
wp-content/debug.log

# WooCommerce logs
wp-content/uploads/wc-logs/inovio-[date]-[hash].log
```

### Adding Debug Statements

```php
// Use WooCommerce logger
$this->common_class->inovio_logger( 'Debug message: ' . print_r( $data, true ), $this );

// Or WordPress error_log
if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
    error_log( 'Inovio Debug: ' . print_r( $data, true ) );
}
```

### Debugging Payment Flow

```php
// Add to process_payment() method
error_log( '=== INOVIO PAYMENT DEBUG ===' );
error_log( 'Order ID: ' . $order_id );
error_log( 'Params: ' . print_r( $params, true ) );
error_log( 'Response: ' . $response );
error_log( 'Parsed Result: ' . print_r( $parse_result, true ) );
```

### Database Query Debugging

```php
// Show MySQL queries
define( 'SAVEQUERIES', true );

// In your code
global $wpdb;
print_r( $wpdb->queries );
```

## Contributing

### Contribution Guidelines

1. **Fork the repository**
2. **Create feature branch** from `develop` (not `main`)
3. **Make your changes** following coding standards
4. **Test thoroughly** (see Testing section)
5. **Commit with clear messages**
6. **Push to your fork**
7. **Create Pull Request** to `develop` branch

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on WordPress 5.x
- [ ] Tested on WooCommerce 4.x
- [ ] Manual testing completed
- [ ] No errors in debug log

## Checklist
- [ ] Code follows WordPress coding standards
- [ ] Comments added for complex logic
- [ ] Documentation updated (if needed)
- [ ] No security vulnerabilities introduced
```

### Code Review Process

1. Maintainer reviews code within 3-5 business days
2. Feedback provided via PR comments
3. Developer addresses feedback
4. Maintainer approves and merges
5. Changes included in next release

## Release Process

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., 4.4.23)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

### Release Checklist

- [ ] Update version in `woocommerce-inovio-gateway.php` header
- [ ] Update version in `readme.txt`
- [ ] Update `Stable tag` in `readme.txt`
- [ ] Add changelog entry in `readme.txt`
- [ ] Test on clean WordPress install
- [ ] Test upgrade from previous version
- [ ] Create git tag: `git tag -a v4.4.24 -m "Release 4.4.24"`
- [ ] Push tag: `git push origin v4.4.24`
- [ ] Create GitHub release with notes
- [ ] Package plugin ZIP (see Packaging section)
- [ ] Upload to WordPress.org (if applicable)
- [ ] Notify stakeholders

### Packaging for Distribution

```bash
#!/bin/bash
# Package script: package.sh

VERSION="4.4.24"
PLUGIN_SLUG="inovio-payment-gateway"

# Create clean directory
mkdir -p dist
rm -rf dist/$PLUGIN_SLUG

# Copy plugin files
git clone . dist/$PLUGIN_SLUG
cd dist/$PLUGIN_SLUG

# Remove development files
rm -rf .git .gitignore
rm -rf tests/
rm -rf node_modules/
rm package.sh

# Create ZIP
cd ..
zip -r ${PLUGIN_SLUG}-${VERSION}.zip $PLUGIN_SLUG

echo "Package created: dist/${PLUGIN_SLUG}-${VERSION}.zip"
```

---

## Additional Resources

- **WordPress Plugin Handbook**: https://developer.wordpress.org/plugins/
- **WooCommerce Documentation**: https://woocommerce.com/documentation/
- **Inovio API Documentation**: Contact Inovio support
- **WooCommerce Subscriptions**: https://woocommerce.com/document/subscriptions/

## Maintainer Contacts

- **Lead Developer**: [Name] - email@example.com
- **Inovio Technical Support**: clientsupport@inoviopay.com
- **Repository**: [GitHub URL]

---

**Happy Coding!**
