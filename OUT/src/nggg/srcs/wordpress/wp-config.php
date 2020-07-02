<?php

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpressdb' );

/** MySQL database username */
define( 'DB_USER', 'wordpressuser' );

/** MySQL database password */
define( 'DB_PASSWORD', 'wordpresspass' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         '$5fiF[lx)EuhtBV0=_XnBL@RtSjEwL18*|dC;z7p0-C|zL(mget?}3TB>aRrsLl&');
define('SECURE_AUTH_KEY',  '89h2I$.*BuCjWK<ra|3NUPcm?_0lS)Wst-l+SZ.>Fp:r f9hs$Y5CFXyqX#E+daS');
define('LOGGED_IN_KEY',    'Hyl_=&|)5F?{#@|)i+hx+&rt,T::Va I#)0c_s#k# J11LC|M+BM{xpTEuRlZ|6(');
define('NONCE_KEY',        '?)Eiut]s[Li[zj8z8mxg|b{<2~+,Ua{Q>@vn|nu?[j-xs5cJ[x4B_Ul;C*R2F4I]');
define('AUTH_SALT',        'VKXM*_/J|,DzCVklqSBi@|]-mw*Zc+]wr9n51v71>hcoQVpIZC&KDnUb[n8-<WHN');
define('SECURE_AUTH_SALT', '<iqer-i4V? Kar`av<P%+aBE[SnDn!/tin{d<,^A2wsOoZLkakra+6C_0Z$A0#.R');
define('LOGGED_IN_SALT',   '!EPW(Mw-}aD?)Vs?NB!b=s-kV`jUYItCgfNg&!Z%_iky:H6*v2%X:kKNL*LDADGi');
define('NONCE_SALT',       'snYF0weZF2]kY~dj3zwwr[zND<P]<Q)zR-.nO^hz#B4&0)*(hT#.ai2+%1?3K2Am');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
