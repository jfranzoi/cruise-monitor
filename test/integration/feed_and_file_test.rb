require File.dirname(__FILE__) + '/../test_helper'
include Build

class RssAndFileTest < Test::Unit::TestCase
  
  STORAGE_FILE = '/tmp/latest.info'
  ANY_URL = 'http://localhost:10123/any-resource'
  
  def setup
    Utils.delete_if_exists(STORAGE_FILE)
  
    @server = FeedServer.new(10123)
    @server.start
    
    @notifier = StubNotifier.new
  end
  
  def teardown
    @server.stop
    Utils.delete_if_exists(STORAGE_FILE)
  end
  
  def test_should_connect_to_local_feed_and_notify_success_on_build_back_clean
    Utils.write_content(STORAGE_FILE, 'myproject build 1000 failed')
    @server.prepare(feed_file('cruisecontrol.rb.success.rss'))

    monitor = Monitor.failures_on(cruise_at(ANY_URL, STORAGE_FILE), @notifier)
    monitor.sync
    
    assert @notifier.has_notified_success
  end
  
  def test_should_connect_to_local_feed_and_warn_build_failure
    Utils.write_content(STORAGE_FILE, 'myproject build 1000 success')
    @server.prepare(feed_file('cruisecontrol.rb.failed.rss'))
    
    monitor = Monitor.failures_on(cruise_at(ANY_URL, STORAGE_FILE), @notifier)
    monitor.sync
    
    assert @notifier.has_warned
  end

  def test_support_monitoring_on_each_success
    @server.prepare(feed_file('cruisecontrol.rb.success.rss'))

    monitor = Monitor.all_builds_on(cruise_at(ANY_URL, STORAGE_FILE), @notifier)
    monitor.sync
    
    assert @notifier.has_notified_success
  end
  
  def test_support_hudson_on_success
    @server.prepare(feed_file('hudson.success.rss'))

    monitor = Monitor.all_builds_on(hudson_at(ANY_URL, STORAGE_FILE), @notifier)
    monitor.sync
    
    assert @notifier.has_notified_success
  end

  def test_support_hudson_on_failures
    @server.prepare(feed_file('hudson.failed.rss'))

    monitor = Monitor.all_builds_on(hudson_at(ANY_URL, STORAGE_FILE), @notifier)
    monitor.sync
    
    assert @notifier.has_warned
  end
  
  def test_support_ccnet_feed_on_success
    @server.prepare(feed_file('cruisecontrol.net.success.rss'))
    feed = Feed.on(ANY_URL, CruiseControlNetParser.new)
    
    assert_equal 'Cruise SharpDevelop-MAIN-CI 28 success', feed.latest_info
  end
  
  def test_support_ccnet_feed_on_failures
    @server.prepare(feed_file('cruisecontrol.net.failed.rss'))
    feed = Feed.on(ANY_URL, CruiseControlNetParser.new)
    
    assert_equal 'Cruise SharpDevelop-MAIN-CI 30 failed', feed.latest_info
  end

  def test_support_ccnet_page_on_success
    @server.prepare(feed_file('cruisecontrol.net.success.html'))
    feed = Feed.on(ANY_URL, CruiseControlNetHtmlParser.new)
    
    assert_equal 'Cruise SharpDevelop-MAIN-CI 43 success', feed.latest_info
  end

end