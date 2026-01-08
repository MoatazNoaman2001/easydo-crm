--
-- PostgreSQL database dump
--

\restrict bcVgIw5UElfqNtgPVrCb5us8GzecPxEInO8d7RgfFdNh7SocIK3MhlanABoUNg2

-- Dumped from database version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: activity_type; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.activity_type AS ENUM (
    'comment',
    'update',
    'next_follow_up'
);


ALTER TYPE public.activity_type OWNER TO ubuntu;

--
-- Name: campaign_status; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.campaign_status AS ENUM (
    'draft',
    'scheduled',
    'processing',
    'executing',
    'running',
    'completed',
    'cancelled',
    'failed'
);


ALTER TYPE public.campaign_status OWNER TO ubuntu;

--
-- Name: channel; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.channel AS ENUM (
    'incoming',
    'outgoing'
);


ALTER TYPE public.channel OWNER TO ubuntu;

--
-- Name: company_inquiry_status; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.company_inquiry_status AS ENUM (
    'new',
    'contacted',
    'qualified',
    'converted'
);


ALTER TYPE public.company_inquiry_status OWNER TO ubuntu;

--
-- Name: conversation_status; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.conversation_status AS ENUM (
    'closed',
    'open',
    'cancelled',
    'completed'
);


ALTER TYPE public.conversation_status OWNER TO ubuntu;

--
-- Name: file_category; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.file_category AS ENUM (
    'document',
    'image',
    'video',
    'audio',
    'spreadsheet',
    'presentation',
    'other'
);


ALTER TYPE public.file_category OWNER TO ubuntu;

--
-- Name: lead_status; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.lead_status AS ENUM (
    'active',
    'interested',
    'not_interested',
    'bounced'
);


ALTER TYPE public.lead_status OWNER TO ubuntu;

--
-- Name: message_status; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.message_status AS ENUM (
    'read',
    'delivered',
    'sent',
    'failed',
    'pending'
);


ALTER TYPE public.message_status OWNER TO ubuntu;

--
-- Name: message_type; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.message_type AS ENUM (
    'ticket',
    'message',
    'remark'
);


ALTER TYPE public.message_type OWNER TO ubuntu;

--
-- Name: resource_tag_type; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.resource_tag_type AS ENUM (
    'android',
    'ios',
    'starter',
    'business',
    'enterprise'
);


ALTER TYPE public.resource_tag_type OWNER TO ubuntu;

--
-- Name: ticket_creator; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.ticket_creator AS ENUM (
    'user',
    'system',
    'staff'
);


ALTER TYPE public.ticket_creator OWNER TO ubuntu;

--
-- Name: ticket_priority; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.ticket_priority AS ENUM (
    'low',
    'medium',
    'high'
);


ALTER TYPE public.ticket_priority OWNER TO ubuntu;

--
-- Name: ticket_status; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.ticket_status AS ENUM (
    'open',
    'closed',
    'unassigned',
    'inprogress',
    'rejected'
);


ALTER TYPE public.ticket_status OWNER TO ubuntu;

--
-- Name: tutorial_category_type; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.tutorial_category_type AS ENUM (
    'user',
    'non_user'
);


ALTER TYPE public.tutorial_category_type OWNER TO ubuntu;

--
-- Name: tutorial_type; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.tutorial_type AS ENUM (
    'video',
    'document',
    'text'
);


ALTER TYPE public.tutorial_type OWNER TO ubuntu;

--
-- Name: upload_status; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.upload_status AS ENUM (
    'pending',
    'uploading',
    'completed',
    'failed'
);


ALTER TYPE public.upload_status OWNER TO ubuntu;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: ubuntu
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'customer_support'
);


ALTER TYPE public.user_role OWNER TO ubuntu;

--
-- Name: add_customer_on_conversation(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.add_customer_on_conversation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO customers (mobile_number, usernames)
    VALUES (
        NEW.mobile_number,
        ARRAY[NEW.user_name]
    )
    ON CONFLICT (mobile_number) DO UPDATE
    SET usernames = CASE 
        WHEN NEW.user_name IS NOT NULL AND NOT (NEW.user_name = ANY(customers.usernames))
        THEN array_append(customers.usernames, NEW.user_name)
        ELSE customers.usernames
    END;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_customer_on_conversation() OWNER TO ubuntu;

--
-- Name: auto_close_expired_calls(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.auto_close_expired_calls() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
    affected_rows INTEGER;
BEGIN
    UPDATE call 
    SET status = 'closed'::conversation_status, 
        closed_timestamp = NOW()
    WHERE timestamp < NOW() - INTERVAL '2 minutes'
      AND status = 'open'::conversation_status;

    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$;


ALTER FUNCTION public.auto_close_expired_calls() OWNER TO ubuntu;

--
-- Name: fn_mid(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.fn_mid(character varying, integer, integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
declare word alias for $1; 
start alias for $2;
len alias for $3;
begin
return substring(word, start, len);
end;
$_$;


ALTER FUNCTION public.fn_mid(character varying, integer, integer) OWNER TO ubuntu;

--
-- Name: get_user_recent_gemini_uploads(uuid, integer, integer); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.get_user_recent_gemini_uploads(p_user_id uuid, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0) RETURNS TABLE(id uuid, user_id uuid, store_id uuid, store_name character varying, store_display_name character varying, original_name character varying, file_size bigint, mime_type character varying, file_category character varying, description text, tags text[], gemini_file_name character varying, upload_status character varying, error_message text, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gu.id,
        gu.user_id,
        gu.store_id,
        gu.store_name,
        gfs.display_name as store_display_name,
        gu.original_name,
        gu.file_size,
        gu.mime_type,
        gu.file_category,
        gu.description,
        gu.tags,
        gu.gemini_file_name,
        gu.upload_status,
        gu.error_message,
        gu.created_at,
        gu.updated_at
    FROM gemini_uploads gu
    LEFT JOIN gemini_file_search_stores gfs ON gu.store_id = gfs.id
    WHERE gu.user_id = p_user_id 
        AND gu.deleted_at IS NULL
    ORDER BY gu.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;


ALTER FUNCTION public.get_user_recent_gemini_uploads(p_user_id uuid, p_limit integer, p_offset integer) OWNER TO ubuntu;

--
-- Name: get_user_recent_uploads(uuid, integer, integer); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.get_user_recent_uploads(p_user_id uuid, p_limit integer DEFAULT 10, p_offset integer DEFAULT 0) RETURNS TABLE(id uuid, original_filename character varying, file_size bigint, mime_type character varying, file_category public.file_category, drive_file_url text, drive_webview_link text, drive_thumbnail_link text, upload_status public.upload_status, created_at timestamp without time zone, description text, tags text[])
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uu.id,
        uu.original_filename,
        uu.file_size,
        uu.mime_type,
        uu.file_category,
        uu.drive_file_url,
        uu.drive_webview_link,
        uu.drive_thumbnail_link,
        uu.upload_status,
        uu.created_at,
        uu.description,
        uu.tags
    FROM user_uploads uu
    WHERE uu.user_id = p_user_id
    ORDER BY uu.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;


ALTER FUNCTION public.get_user_recent_uploads(p_user_id uuid, p_limit integer, p_offset integer) OWNER TO ubuntu;

--
-- Name: handle_customer_opt_in(character varying); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.handle_customer_opt_in(p_mobile_number character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE customers
    SET 
        lead_status = 'interested',
        consent_given = TRUE,
        opt_out_at = NULL,
        opt_out_reason = NULL,
        last_interaction_at = NOW()
    WHERE mobile_number = p_mobile_number;
    
    INSERT INTO lead_interactions (
        mobile_number,
        interaction_type,
        interaction_data
    ) VALUES (
        p_mobile_number,
        'opt_in',
        jsonb_build_object('timestamp', NOW())
    );
END;
$$;


ALTER FUNCTION public.handle_customer_opt_in(p_mobile_number character varying) OWNER TO ubuntu;

--
-- Name: handle_customer_opt_out(character varying, character varying); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.handle_customer_opt_out(p_mobile_number character varying, p_reason character varying DEFAULT 'user_request'::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE customers
    SET 
        lead_status = 'not_interested',
        opt_out_at = NOW(),
        opt_out_reason = p_reason
    WHERE mobile_number = p_mobile_number;
    
    INSERT INTO lead_interactions (
        mobile_number,
        interaction_type,
        interaction_data
    ) VALUES (
        p_mobile_number,
        'opt_out',
        jsonb_build_object('reason', p_reason, 'timestamp', NOW())
    );
END;
$$;


ALTER FUNCTION public.handle_customer_opt_out(p_mobile_number character varying, p_reason character varying) OWNER TO ubuntu;

--
-- Name: increment_failed_message_count(character varying, integer); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.increment_failed_message_count(p_mobile_number character varying, p_error_code integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE customers
    SET 
        failed_message_count = failed_message_count + 1,
        lead_status = CASE 
            WHEN failed_message_count + 1 >= 3 THEN 'bounced'::lead_status
            ELSE lead_status
        END
    WHERE mobile_number = p_mobile_number;
    
    -- Log the interaction
    INSERT INTO lead_interactions (
        mobile_number,
        interaction_type,
        interaction_data
    ) VALUES (
        p_mobile_number,
        'message_failed',
        jsonb_build_object(
            'error_code', p_error_code,
            'timestamp', NOW(),
            'failed_count', (SELECT failed_message_count FROM customers WHERE mobile_number = p_mobile_number)
        )
    );
END;
$$;


ALTER FUNCTION public.increment_failed_message_count(p_mobile_number character varying, p_error_code integer) OWNER TO ubuntu;

--
-- Name: notify_campaign_status_change(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.notify_campaign_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    payload JSON;
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        payload := json_build_object(
            'campaign_id', NEW.id,
            'campaign_name', NEW.name,
            'old_status', OLD.status,
            'new_status', NEW.status,
            'updated_at', NEW.updated_at
        );
        
        -- Send notification
        PERFORM pg_notify('campaign_status_changed', payload::text);
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.notify_campaign_status_change() OWNER TO ubuntu;

--
-- Name: FUNCTION notify_campaign_status_change(); Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON FUNCTION public.notify_campaign_status_change() IS 'Notifies admins when campaign status changes via PostgreSQL NOTIFY';


--
-- Name: notify_user_status_change(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.notify_user_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  payload JSON;
BEGIN
  -- Only notify if is_online status actually changed
  IF (TG_OP = 'UPDATE' AND OLD.is_online IS DISTINCT FROM NEW.is_online) THEN
    payload = json_build_object(
      'user_id', NEW.id,
      'name', NEW.name,
      'email', NEW.email,
      'role', NEW.role,
      'is_online', NEW.is_online,
      'was_online', OLD.is_online,
      'mobile_number', NEW.mobile_number,
      'profile_image', NEW.profile_image,
      'timestamp', extract(epoch from now())
    );
    
    -- Send notification on 'user_status_changed' channel
    PERFORM pg_notify('user_status_changed', payload::text);
    
    RAISE NOTICE 'User status changed: % is now %', NEW.name, 
      CASE WHEN NEW.is_online THEN 'ONLINE' ELSE 'OFFLINE' END;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.notify_user_status_change() OWNER TO ubuntu;

--
-- Name: search_uploads_by_tags(integer, text[]); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.search_uploads_by_tags(p_user_id integer, p_tags text[]) RETURNS TABLE(id uuid, original_filename character varying, file_category public.file_category, drive_webview_link text, tags text[], created_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uu.id,
        uu.original_filename,
        uu.file_category,
        uu.drive_webview_link,
        uu.tags,
        uu.created_at
    FROM user_uploads uu
    WHERE uu.user_id = p_user_id 
        AND uu.deleted_at IS NULL
        AND uu.tags && p_tags -- Array overlap operator
    ORDER BY uu.created_at DESC;
END;
$$;


ALTER FUNCTION public.search_uploads_by_tags(p_user_id integer, p_tags text[]) OWNER TO ubuntu;

--
-- Name: set_assigned_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.set_assigned_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.assigned_to IS NOT NULL AND OLD.assigned_to IS NULL THEN
        NEW.assigned_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_assigned_at() OWNER TO ubuntu;

--
-- Name: update_campaign_message_status_updated_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_campaign_message_status_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_campaign_message_status_updated_at() OWNER TO ubuntu;

--
-- Name: update_campaign_statistics(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_campaign_statistics() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_recipients INT;
    v_delivered_count INT;
    v_read_count INT;
BEGIN
    -- Get current stats for the campaign
    SELECT total_recipients, delivered_count, read_count
    INTO v_total_recipients, v_delivered_count, v_read_count
    FROM campaign_statistics
    WHERE campaign_id = NEW.campaign_id;
    
    -- Handle status changes
    IF NEW.status = 'sent' AND (OLD.status IS NULL OR OLD.status != 'sent') THEN
        UPDATE campaign_statistics 
        SET sent_count = sent_count + 1,
            queued_count = GREATEST(queued_count - 1, 0),
            first_sent_at = COALESCE(first_sent_at, NEW.sent_at),
            last_sent_at = NEW.sent_at,
            last_updated_at = NOW()
        WHERE campaign_id = NEW.campaign_id;
        
    ELSIF NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered') THEN
        UPDATE campaign_statistics 
        SET delivered_count = delivered_count + 1,
            -- Absolute rate: delivered / total_recipients
            delivery_rate = CASE WHEN v_total_recipients > 0 
                           THEN ((delivered_count + 1)::DECIMAL / v_total_recipients * 100)
                           ELSE 0 END,
            last_updated_at = NOW()
        WHERE campaign_id = NEW.campaign_id;
        
    ELSIF NEW.status = 'read' AND (OLD.status IS NULL OR OLD.status != 'read') THEN
        UPDATE campaign_statistics 
        SET read_count = read_count + 1,
            -- Absolute rate: read / total_recipients
            read_rate_absolute = CASE WHEN v_total_recipients > 0 
                                THEN ((read_count + 1)::DECIMAL / v_total_recipients * 100)
                                ELSE 0 END,
            -- Funnel rate: read / delivered
            read_rate_funnel = CASE WHEN v_delivered_count > 0 
                              THEN ((read_count + 1)::DECIMAL / v_delivered_count * 100)
                              ELSE 0 END,
            last_updated_at = NOW()
        WHERE campaign_id = NEW.campaign_id;
        
    ELSIF NEW.status = 'failed' AND (OLD.status IS NULL OR OLD.status != 'failed') THEN
        UPDATE campaign_statistics 
        SET failed_count = failed_count + 1,
            queued_count = GREATEST(queued_count - 1, 0),
            -- Absolute rate: failed / total_recipients
            failure_rate = CASE WHEN v_total_recipients > 0 
                          THEN ((failed_count + 1)::DECIMAL / v_total_recipients * 100)
                          ELSE 0 END,
            last_updated_at = NOW()
        WHERE campaign_id = NEW.campaign_id;
    END IF;
    
    -- Update clicked count
    IF NEW.clicked_at IS NOT NULL AND (OLD.clicked_at IS NULL) THEN
        -- Re-fetch counts
        SELECT total_recipients, read_count INTO v_total_recipients, v_read_count
        FROM campaign_statistics
        WHERE campaign_id = NEW.campaign_id;
        
        UPDATE campaign_statistics 
        SET clicked_count = clicked_count + 1,
            -- Absolute rate: clicked / total_recipients
            click_rate_absolute = CASE WHEN v_total_recipients > 0 
                                 THEN ((clicked_count + 1)::DECIMAL / v_total_recipients * 100)
                                 ELSE 0 END,
            -- Funnel rate: clicked / read
            click_rate_funnel = CASE WHEN v_read_count > 0 
                               THEN ((clicked_count + 1)::DECIMAL / v_read_count * 100)
                               ELSE 0 END,
            last_updated_at = NOW()
        WHERE campaign_id = NEW.campaign_id;
    END IF;
    
    -- Update replied count
    IF NEW.replied_at IS NOT NULL AND (OLD.replied_at IS NULL) THEN
        -- Re-fetch counts
        SELECT total_recipients, read_count INTO v_total_recipients, v_read_count
        FROM campaign_statistics
        WHERE campaign_id = NEW.campaign_id;
        
        UPDATE campaign_statistics 
        SET replied_count = replied_count + 1,
            -- Absolute rate: replied / total_recipients
            reply_rate_absolute = CASE WHEN v_total_recipients > 0 
                                 THEN ((replied_count + 1)::DECIMAL / v_total_recipients * 100)
                                 ELSE 0 END,
            -- Funnel rate: replied / read
            reply_rate_funnel = CASE WHEN v_read_count > 0 
                               THEN ((replied_count + 1)::DECIMAL / v_read_count * 100)
                               ELSE 0 END,
            last_updated_at = NOW()
        WHERE campaign_id = NEW.campaign_id;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_campaign_statistics() OWNER TO ubuntu;

--
-- Name: update_campaigns_updated_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_campaigns_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_campaigns_updated_at() OWNER TO ubuntu;

--
-- Name: update_customer_last_interaction(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_customer_last_interaction() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE customers 
    SET last_interaction_at = NOW()
    WHERE mobile_number = NEW.mobile_number;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_customer_last_interaction() OWNER TO ubuntu;

--
-- Name: update_gemini_settings_timestamp(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_gemini_settings_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_gemini_settings_timestamp() OWNER TO ubuntu;

--
-- Name: update_gemini_timestamp(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_gemini_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_gemini_timestamp() OWNER TO ubuntu;

--
-- Name: update_last_updated_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_last_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_last_updated_at() OWNER TO ubuntu;

--
-- Name: update_template_flow_states_updated_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_template_flow_states_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_template_flow_states_updated_at() OWNER TO ubuntu;

--
-- Name: update_template_flows_updated_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_template_flows_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_template_flows_updated_at() OWNER TO ubuntu;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO ubuntu;

--
-- Name: update_user_flow_status_updated_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_user_flow_status_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_user_flow_status_updated_at() OWNER TO ubuntu;

--
-- Name: update_user_uploads_updated_at(); Type: FUNCTION; Schema: public; Owner: ubuntu
--

CREATE FUNCTION public.update_user_uploads_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_user_uploads_updated_at() OWNER TO ubuntu;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bulk_messages; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.bulk_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid,
    tamplet_name character varying(225) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    total_recipients integer NOT NULL,
    sent_count integer DEFAULT 0,
    failed_count integer DEFAULT 0,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now(),
    completed_at timestamp without time zone
);


ALTER TABLE public.bulk_messages OWNER TO ubuntu;

--
-- Name: call; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.call (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    status public.conversation_status DEFAULT 'open'::public.conversation_status NOT NULL,
    customer_support uuid,
    mobile_number character varying NOT NULL,
    user_name character varying,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_timestamp timestamp without time zone,
    rating integer DEFAULT 5,
    reason character varying,
    query character varying,
    timeslot character varying,
    query_bucket character varying
);


ALTER TABLE public.call OWNER TO ubuntu;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.customers (
    mobile_number character varying NOT NULL,
    usernames text[],
    gid uuid,
    utm_source character varying(100) DEFAULT 'unknown'::character varying,
    lead_status public.lead_status DEFAULT 'active'::public.lead_status,
    last_interaction_at timestamp without time zone,
    opt_out_at timestamp without time zone,
    opt_out_reason character varying(255),
    consent_given boolean DEFAULT false,
    failed_message_count integer DEFAULT 0,
    last_consent_message_sent timestamp without time zone,
    easydo_user_id integer,
    user_name character varying(255),
    email character varying(255),
    country_code character varying(10),
    time_zone character varying(100),
    dob date,
    user_status text,
    last_seen_time timestamp without time zone,
    company character varying(255),
    subscription_type character varying(50),
    subscription_status character varying(20),
    subscription_end_date timestamp without time zone,
    subscription_amount numeric(10,2),
    total_employees_allowed integer,
    employee_count character varying(50),
    inquiry_departments jsonb,
    inquiry_help_options jsonb,
    inquiry_status character varying(50),
    last_inquiry_at timestamp without time zone,
    first_inquiry_at timestamp without time zone,
    app_first_download timestamp without time zone,
    total_inquiries integer DEFAULT 0,
    all_companies jsonb,
    all_emails jsonb,
    all_departments jsonb,
    last_campaign_sent_at timestamp without time zone,
    last_campaign_type character varying(100),
    campaign_sent_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    last_synced_at timestamp without time zone
);


ALTER TABLE public.customers OWNER TO ubuntu;

--
-- Name: COLUMN customers.utm_source; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.customers.utm_source IS 'Source of the lead: dashboard_manual, whatsapp_direct, facebook_ad, google_ad, website, etc.';


--
-- Name: COLUMN customers.lead_status; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.customers.lead_status IS 'Current status of the lead for campaign eligibility';


--
-- Name: COLUMN customers.consent_given; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.customers.consent_given IS 'Whether the user has given explicit consent to receive messages';


--
-- Name: COLUMN customers.failed_message_count; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.customers.failed_message_count IS 'Number of consecutive failed message deliveries';


--
-- Name: campaign_eligible_customers; Type: VIEW; Schema: public; Owner: ubuntu
--

CREATE VIEW public.campaign_eligible_customers AS
 SELECT mobile_number,
    usernames,
    gid,
    utm_source,
    lead_status,
    last_interaction_at,
    opt_out_at,
    opt_out_reason,
    consent_given,
    failed_message_count,
        CASE
            WHEN (lead_status = 'not_interested'::public.lead_status) THEN false
            WHEN (failed_message_count >= 3) THEN false
            WHEN (((utm_source)::text = 'dashboard_manual'::text) AND (consent_given = false)) THEN false
            ELSE true
        END AS is_eligible_for_campaign
   FROM public.customers c;


ALTER VIEW public.campaign_eligible_customers OWNER TO ubuntu;

--
-- Name: campaign_message_errors; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.campaign_message_errors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid,
    mobile_number character varying NOT NULL,
    whatsapp_message_id character varying,
    error_code integer NOT NULL,
    error_title character varying(500),
    error_message text,
    error_details jsonb,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.campaign_message_errors OWNER TO ubuntu;

--
-- Name: TABLE campaign_message_errors; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TABLE public.campaign_message_errors IS 'Detailed error tracking for campaign messages';


--
-- Name: campaign_message_status; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.campaign_message_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid,
    bulk_message_id uuid,
    recipient_number character varying(20) NOT NULL,
    recipient_name character varying(255),
    whatsapp_message_id character varying(255),
    status character varying(20) DEFAULT 'queued'::character varying NOT NULL,
    queued_at timestamp without time zone DEFAULT now(),
    sent_at timestamp without time zone,
    delivered_at timestamp without time zone,
    read_at timestamp without time zone,
    clicked_at timestamp without time zone,
    replied_at timestamp without time zone,
    failed_at timestamp without time zone,
    error_code character varying(50),
    error_message text,
    error_details jsonb,
    template_name character varying(255),
    template_language character varying(10),
    template_variables jsonb,
    message_cost numeric(10,4),
    conversation_category character varying(50),
    retry_count integer DEFAULT 0,
    last_retry_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.campaign_message_status OWNER TO ubuntu;

--
-- Name: TABLE campaign_message_status; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TABLE public.campaign_message_status IS 'Tracks individual message status for each recipient in a campaign or bulk message';


--
-- Name: COLUMN campaign_message_status.whatsapp_message_id; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_message_status.whatsapp_message_id IS 'Unique message ID from WhatsApp (NULL until message is sent)';


--
-- Name: COLUMN campaign_message_status.status; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_message_status.status IS 'Current message status: queued, sent, delivered, read, failed, clicked, replied';


--
-- Name: COLUMN campaign_message_status.conversation_category; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_message_status.conversation_category IS 'WhatsApp conversation category for pricing';


--
-- Name: campaign_statistics; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.campaign_statistics (
    campaign_id uuid NOT NULL,
    bulk_message_id uuid,
    total_recipients integer DEFAULT 0,
    queued_count integer DEFAULT 0,
    sent_count integer DEFAULT 0,
    delivered_count integer DEFAULT 0,
    read_count integer DEFAULT 0,
    clicked_count integer DEFAULT 0,
    replied_count integer DEFAULT 0,
    failed_count integer DEFAULT 0,
    delivery_rate numeric(5,2) DEFAULT 0.00,
    read_rate_funnel numeric(5,2) DEFAULT 0.00,
    click_rate_funnel numeric(5,2) DEFAULT 0.00,
    reply_rate_funnel numeric(5,2) DEFAULT 0.00,
    failure_rate numeric(5,2) DEFAULT 0.00,
    total_cost numeric(10,2) DEFAULT 0.00,
    first_sent_at timestamp without time zone,
    last_sent_at timestamp without time zone,
    last_updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    read_rate_absolute numeric(5,2) DEFAULT 0.00,
    click_rate_absolute numeric(5,2) DEFAULT 0.00,
    reply_rate_absolute numeric(5,2) DEFAULT 0.00
);


ALTER TABLE public.campaign_statistics OWNER TO ubuntu;

--
-- Name: TABLE campaign_statistics; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TABLE public.campaign_statistics IS 'Aggregated statistics for campaigns to avoid expensive COUNT queries';


--
-- Name: COLUMN campaign_statistics.delivery_rate; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.delivery_rate IS 'Absolute: Percentage of total recipients who received the message';


--
-- Name: COLUMN campaign_statistics.read_rate_funnel; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.read_rate_funnel IS 'Funnel: Percentage of delivered messages that were read';


--
-- Name: COLUMN campaign_statistics.click_rate_funnel; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.click_rate_funnel IS 'Funnel: Percentage of read messages where links were clicked';


--
-- Name: COLUMN campaign_statistics.reply_rate_funnel; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.reply_rate_funnel IS 'Funnel: Percentage of read messages that received replies';


--
-- Name: COLUMN campaign_statistics.failure_rate; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.failure_rate IS 'Absolute: Percentage of total recipients where delivery failed';


--
-- Name: COLUMN campaign_statistics.read_rate_absolute; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.read_rate_absolute IS 'Absolute: Percentage of total recipients who read the message';


--
-- Name: COLUMN campaign_statistics.click_rate_absolute; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.click_rate_absolute IS 'Absolute: Percentage of total recipients who clicked links';


--
-- Name: COLUMN campaign_statistics.reply_rate_absolute; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.campaign_statistics.reply_rate_absolute IS 'Absolute: Percentage of total recipients who replied';


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    status public.campaign_status DEFAULT 'draft'::public.campaign_status NOT NULL,
    group_id uuid,
    phone_numbers text[],
    template_name character varying(255) NOT NULL,
    scheduled_at timestamp without time zone NOT NULL,
    executed_at timestamp without time zone,
    bulk_message_id uuid,
    total_recipients integer DEFAULT 0,
    sent_count integer DEFAULT 0,
    failed_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    created_by uuid,
    error_message text,
    template_code character varying(255),
    template_params jsonb DEFAULT '{}'::jsonb,
    template_type character varying(15) DEFAULT 'Not Provided'::character varying NOT NULL,
    queue_job_id character varying(100),
    queue_status character varying(20) DEFAULT 'pending'::character varying,
    queued_at timestamp without time zone,
    processing_started_at timestamp without time zone,
    processing_completed_at timestamp without time zone,
    CONSTRAINT campaigns_target_check CHECK (((group_id IS NOT NULL) OR ((phone_numbers IS NOT NULL) AND (array_length(phone_numbers, 1) > 0))))
);


ALTER TABLE public.campaigns OWNER TO ubuntu;

--
-- Name: chat_attachments; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.chat_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    original_name character varying(255) NOT NULL,
    file_path character varying(500) NOT NULL,
    file_size bigint NOT NULL,
    mime_type character varying(100) NOT NULL,
    conversation_id uuid NOT NULL,
    uploaded_by uuid,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.chat_attachments OWNER TO ubuntu;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.companies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.companies OWNER TO ubuntu;

--
-- Name: company_gemini_config; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.company_gemini_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    gemini_api_key_encrypted text NOT NULL,
    gemini_api_key_iv text NOT NULL,
    gemini_api_key_tag text NOT NULL,
    bot_active boolean DEFAULT false,
    bot_name character varying(100) DEFAULT 'AI Assistant'::character varying,
    bot_description text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);


ALTER TABLE public.company_gemini_config OWNER TO ubuntu;

--
-- Name: company_inquiries; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.company_inquiries (
    id integer NOT NULL,
    company_name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    employee_count character varying(50) NOT NULL,
    departments jsonb NOT NULL,
    help_options jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    status public.company_inquiry_status DEFAULT 'new'::public.company_inquiry_status NOT NULL,
    phone_number character varying(24) DEFAULT 'Not Provided'::character varying NOT NULL
);


ALTER TABLE public.company_inquiries OWNER TO ubuntu;

--
-- Name: company_inquiries_id_seq; Type: SEQUENCE; Schema: public; Owner: ubuntu
--

CREATE SEQUENCE public.company_inquiries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.company_inquiries_id_seq OWNER TO ubuntu;

--
-- Name: company_inquiries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubuntu
--

ALTER SEQUENCE public.company_inquiries_id_seq OWNED BY public.company_inquiries.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    status public.conversation_status DEFAULT 'open'::public.conversation_status NOT NULL,
    customer_support uuid NOT NULL,
    mobile_number character varying NOT NULL,
    user_name character varying,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_timestamp timestamp without time zone,
    rating integer DEFAULT 5,
    reason character varying,
    ticket_id uuid,
    is_rated boolean DEFAULT false
);


ALTER TABLE public.conversations OWNER TO ubuntu;

--
-- Name: customers_groups; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.customers_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    gname character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.customers_groups OWNER TO ubuntu;

--
-- Name: gemini_config_audit_log; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.gemini_config_audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    action character varying(50) NOT NULL,
    performed_by uuid NOT NULL,
    ip_address inet,
    user_agent text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.gemini_config_audit_log OWNER TO ubuntu;

--
-- Name: gemini_file_search_stores; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.gemini_file_search_stores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    store_name character varying(255) NOT NULL,
    display_name character varying(255) NOT NULL,
    description text,
    gemini_metadata jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    apikey character varying(50) DEFAULT 'will be inserted'::character varying NOT NULL
);


ALTER TABLE public.gemini_file_search_stores OWNER TO ubuntu;

--
-- Name: TABLE gemini_file_search_stores; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TABLE public.gemini_file_search_stores IS 'Stores information about Gemini File Search stores created by users';


--
-- Name: gemini_settings; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.gemini_settings (
    id integer NOT NULL,
    api_key text NOT NULL,
    model_name character varying(255) DEFAULT 'gemini-2.0-flash-exp'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    updated_by uuid
);


ALTER TABLE public.gemini_settings OWNER TO ubuntu;

--
-- Name: gemini_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: ubuntu
--

CREATE SEQUENCE public.gemini_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gemini_settings_id_seq OWNER TO ubuntu;

--
-- Name: gemini_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubuntu
--

ALTER SEQUENCE public.gemini_settings_id_seq OWNED BY public.gemini_settings.id;


--
-- Name: gemini_uploads; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.gemini_uploads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    store_id uuid NOT NULL,
    store_name character varying(255) NOT NULL,
    original_name character varying(500) NOT NULL,
    file_size bigint NOT NULL,
    mime_type character varying(255) NOT NULL,
    file_category character varying(50) NOT NULL,
    local_path text,
    description text,
    tags text[] DEFAULT '{}'::text[],
    gemini_file_name character varying(500),
    chunking_config jsonb,
    custom_metadata jsonb,
    operation_response jsonb,
    upload_status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone
);


ALTER TABLE public.gemini_uploads OWNER TO ubuntu;

--
-- Name: TABLE gemini_uploads; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TABLE public.gemini_uploads IS 'Tracks files uploaded to Gemini File Search with their metadata and status';


--
-- Name: COLUMN gemini_uploads.file_category; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.gemini_uploads.file_category IS 'Category: document, spreadsheet, presentation, data, others';


--
-- Name: COLUMN gemini_uploads.upload_status; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.gemini_uploads.upload_status IS 'Status: pending, indexing, completed, failed';


--
-- Name: users; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    role public.user_role NOT NULL,
    is_active boolean DEFAULT true,
    password character varying NOT NULL,
    email character varying NOT NULL,
    mobile_number character varying NOT NULL,
    profile_image character varying,
    query_buckets text[] DEFAULT '{}'::text[],
    is_online boolean DEFAULT false NOT NULL,
    company_id uuid,
    can_manage_bot_settings boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO ubuntu;

--
-- Name: gemini_user_statistics; Type: VIEW; Schema: public; Owner: ubuntu
--

CREATE VIEW public.gemini_user_statistics AS
 SELECT u.id AS user_id,
    count(DISTINCT gfs.id) AS total_stores,
    count(gu.id) AS total_uploads,
    count(gu.id) FILTER (WHERE ((gu.upload_status)::text = 'completed'::text)) AS successful_uploads,
    count(gu.id) FILTER (WHERE ((gu.upload_status)::text = 'failed'::text)) AS failed_uploads,
    count(gu.id) FILTER (WHERE ((gu.upload_status)::text = 'pending'::text)) AS pending_uploads,
    COALESCE(sum(gu.file_size), (0)::numeric) AS total_size_bytes,
    max(gu.created_at) AS last_upload_at
   FROM ((public.users u
     LEFT JOIN public.gemini_file_search_stores gfs ON (((u.id = gfs.user_id) AND (gfs.deleted_at IS NULL))))
     LEFT JOIN public.gemini_uploads gu ON (((u.id = gu.user_id) AND (gu.deleted_at IS NULL))))
  GROUP BY u.id;


ALTER VIEW public.gemini_user_statistics OWNER TO ubuntu;

--
-- Name: languages; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    language character varying NOT NULL
);


ALTER TABLE public.languages OWNER TO ubuntu;

--
-- Name: lead_interactions; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.lead_interactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mobile_number character varying NOT NULL,
    interaction_type character varying(50) NOT NULL,
    campaign_id uuid,
    template_name character varying(255),
    interaction_data jsonb,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.lead_interactions OWNER TO ubuntu;

--
-- Name: TABLE lead_interactions; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TABLE public.lead_interactions IS 'Tracks all interactions with leads for compliance and analytics';


--
-- Name: media_files; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.media_files (
    id integer NOT NULL,
    media_id character varying(255) NOT NULL,
    whatsapp_message_id character varying(255),
    file_path character varying(500) NOT NULL,
    file_size bigint,
    mime_type character varying(100),
    message_type character varying(20),
    download_status character varying(20) DEFAULT 'pending'::character varying,
    downloaded_at timestamp without time zone,
    phone_number character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_download_status CHECK (((download_status)::text = ANY ((ARRAY['pending'::character varying, 'downloading'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.media_files OWNER TO ubuntu;

--
-- Name: media_files_id_seq; Type: SEQUENCE; Schema: public; Owner: ubuntu
--

CREATE SEQUENCE public.media_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.media_files_id_seq OWNER TO ubuntu;

--
-- Name: media_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubuntu
--

ALTER SEQUENCE public.media_files_id_seq OWNED BY public.media_files.id;


--
-- Name: menuoptions; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.menuoptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    is_enabled boolean DEFAULT false,
    priority integer DEFAULT 0
);


ALTER TABLE public.menuoptions OWNER TO ubuntu;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message character varying NOT NULL,
    status public.message_status NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    delivered_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    receive_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    channel public.channel NOT NULL,
    conversation_id uuid NOT NULL,
    whatsapp_message_id character varying,
    message_type public.message_type DEFAULT 'message'::public.message_type NOT NULL,
    message_reply_id uuid,
    media_id character varying(255),
    media_mime_type character varying(100),
    transcription text,
    media_file_path character varying(500),
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    seen_timestamp timestamp without time zone
);


ALTER TABLE public.messages OWNER TO ubuntu;

--
-- Name: querytype; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.querytype (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    is_enabled boolean DEFAULT false,
    query_bucket character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.querytype OWNER TO ubuntu;

--
-- Name: reportdocuments; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.reportdocuments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    is_enabled boolean DEFAULT false
);


ALTER TABLE public.reportdocuments OWNER TO ubuntu;

--
-- Name: template_flow_states; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.template_flow_states (
    id integer NOT NULL,
    flow_id uuid NOT NULL,
    user_phone character varying(20) NOT NULL,
    current_node_id character varying(100) NOT NULL,
    last_whatsapp_message_id character varying(100),
    session_data jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.template_flow_states OWNER TO ubuntu;

--
-- Name: template_flow_states_id_seq; Type: SEQUENCE; Schema: public; Owner: ubuntu
--

CREATE SEQUENCE public.template_flow_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.template_flow_states_id_seq OWNER TO ubuntu;

--
-- Name: template_flow_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubuntu
--

ALTER SEQUENCE public.template_flow_states_id_seq OWNED BY public.template_flow_states.id;


--
-- Name: template_flows; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.template_flows (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    nodes jsonb DEFAULT '[]'::jsonb NOT NULL,
    connections jsonb DEFAULT '[]'::jsonb NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid,
    button_actions jsonb DEFAULT '[]'::jsonb NOT NULL
);


ALTER TABLE public.template_flows OWNER TO ubuntu;

--
-- Name: COLUMN template_flows.button_actions; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.template_flows.button_actions IS 'Button actions configuration for flow buttons';


--
-- Name: ticketactivity; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.ticketactivity (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    activity_type public.activity_type NOT NULL,
    ticket_id uuid NOT NULL,
    comment character varying,
    creator_name character varying,
    creator_email character varying
);


ALTER TABLE public.ticketactivity OWNER TO ubuntu;

--
-- Name: tickets; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.tickets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_number integer NOT NULL,
    created_by public.ticket_creator NOT NULL,
    creator_id character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    title character varying,
    description character varying,
    next_follow_up timestamp without time zone,
    assigned_to uuid,
    activities text[],
    assigned_at timestamp without time zone,
    status public.ticket_status NOT NULL,
    rating integer DEFAULT 5,
    remarks character varying,
    closed_at timestamp without time zone,
    priority public.ticket_priority
);


ALTER TABLE public.tickets OWNER TO ubuntu;

--
-- Name: tutorial_category; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.tutorial_category (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    cat_type public.tutorial_category_type DEFAULT 'user'::public.tutorial_category_type
);


ALTER TABLE public.tutorial_category OWNER TO ubuntu;

--
-- Name: COLUMN tutorial_category.cat_type; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.tutorial_category.cat_type IS 'Category type: user (for registered users) or non_user (for public/non-registered users)';


--
-- Name: tutorial_resources; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.tutorial_resources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tutorial_id uuid NOT NULL,
    description character varying NOT NULL,
    type public.tutorial_type NOT NULL,
    is_enabled boolean DEFAULT false,
    text character varying NOT NULL,
    language character varying DEFAULT 'english'::character varying NOT NULL,
    resource_tag public.resource_tag_type
);


ALTER TABLE public.tutorial_resources OWNER TO ubuntu;

--
-- Name: COLUMN tutorial_resources.resource_tag; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.tutorial_resources.resource_tag IS 'Resource tag for categorizing resources: android/ios for app downloads, starter/business/enterprise for subscriptions';


--
-- Name: tutorials; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.tutorials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    category uuid
);


ALTER TABLE public.tutorials OWNER TO ubuntu;

--
-- Name: user_flow_status; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.user_flow_status (
    id integer NOT NULL,
    phone_number character varying(20) NOT NULL,
    has_completed_inquiry boolean DEFAULT false,
    inquiry_completed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.user_flow_status OWNER TO ubuntu;

--
-- Name: user_flow_status_id_seq; Type: SEQUENCE; Schema: public; Owner: ubuntu
--

CREATE SEQUENCE public.user_flow_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_flow_status_id_seq OWNER TO ubuntu;

--
-- Name: user_flow_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ubuntu
--

ALTER SEQUENCE public.user_flow_status_id_seq OWNED BY public.user_flow_status.id;


--
-- Name: user_uploads; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.user_uploads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    original_filename character varying(500) NOT NULL,
    file_size bigint NOT NULL,
    mime_type character varying(200) NOT NULL,
    file_category public.file_category NOT NULL,
    drive_file_id character varying(500),
    drive_file_url text,
    drive_webview_link text,
    drive_thumbnail_link text,
    local_file_path text,
    upload_status public.upload_status DEFAULT 'pending'::public.upload_status,
    upload_started_at timestamp without time zone,
    upload_completed_at timestamp without time zone,
    error_message text,
    retry_count integer DEFAULT 0,
    description text,
    tags text[],
    is_public boolean DEFAULT false,
    shared_with integer[],
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.user_uploads OWNER TO ubuntu;

--
-- Name: TABLE user_uploads; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TABLE public.user_uploads IS 'Stores user file uploads with Google Drive integration metadata';


--
-- Name: COLUMN user_uploads.drive_file_id; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.user_uploads.drive_file_id IS 'Unique file identifier from Google Drive';


--
-- Name: COLUMN user_uploads.tags; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.user_uploads.tags IS 'Searchable tags for file categorization';


--
-- Name: COLUMN user_uploads.shared_with; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON COLUMN public.user_uploads.shared_with IS 'Array of user IDs who have access to this file';


--
-- Name: user_upload_statistics; Type: VIEW; Schema: public; Owner: ubuntu
--

CREATE VIEW public.user_upload_statistics AS
 SELECT u.id AS user_id,
    u.name,
    u.email,
    count(uu.id) AS total_uploads,
    count(
        CASE
            WHEN (uu.upload_status = 'completed'::public.upload_status) THEN 1
            ELSE NULL::integer
        END) AS successful_uploads,
    count(
        CASE
            WHEN (uu.upload_status = 'failed'::public.upload_status) THEN 1
            ELSE NULL::integer
        END) AS failed_uploads,
    sum(uu.file_size) AS total_storage_used,
    max(uu.created_at) AS last_upload_date
   FROM (public.users u
     LEFT JOIN public.user_uploads uu ON (((u.id = uu.user_id) AND (uu.deleted_at IS NULL))))
  GROUP BY u.id, u.name, u.email;


ALTER VIEW public.user_upload_statistics OWNER TO ubuntu;

--
-- Name: webhook_entities; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.webhook_entities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    display_name character varying(100) NOT NULL,
    target_table character varying(100) NOT NULL,
    identifier_field character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.webhook_entities OWNER TO ubuntu;

--
-- Name: webhook_entity_fields; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.webhook_entity_fields (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    field_name character varying(100) NOT NULL,
    display_name character varying(100) NOT NULL,
    field_type character varying(50) NOT NULL,
    is_required boolean DEFAULT false,
    is_identifier boolean DEFAULT false,
    default_value text,
    description text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.webhook_entity_fields OWNER TO ubuntu;

--
-- Name: webhook_event_params; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.webhook_event_params (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trigger_event_id uuid NOT NULL,
    param_type character varying(20) NOT NULL,
    param_index integer DEFAULT 0 NOT NULL,
    source character varying(20) NOT NULL,
    payload_path character varying(200),
    static_value text,
    created_at timestamp without time zone DEFAULT now(),
    customer_field character varying(100),
    CONSTRAINT webhook_event_params_param_type_check CHECK (((param_type)::text = ANY ((ARRAY['header'::character varying, 'body'::character varying, 'button'::character varying])::text[]))),
    CONSTRAINT webhook_event_params_source_check CHECK (((source)::text = ANY ((ARRAY['payload'::character varying, 'static'::character varying, 'customer'::character varying])::text[])))
);


ALTER TABLE public.webhook_event_params OWNER TO ubuntu;

--
-- Name: webhook_field_mappings; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.webhook_field_mappings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trigger_id uuid NOT NULL,
    entity_field_id uuid NOT NULL,
    external_param character varying(255) NOT NULL,
    transform_type character varying(50) DEFAULT 'direct'::character varying,
    default_value text,
    is_required boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.webhook_field_mappings OWNER TO ubuntu;

--
-- Name: webhook_logs; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.webhook_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type character varying(100) NOT NULL,
    phone_number character varying(500),
    payload jsonb NOT NULL,
    processed boolean DEFAULT false,
    error_message text,
    received_at timestamp without time zone DEFAULT now(),
    processed_at timestamp without time zone,
    trigger_id uuid,
    entity_id uuid,
    action_type character varying(50),
    records_affected integer DEFAULT 0
);


ALTER TABLE public.webhook_logs OWNER TO ubuntu;

--
-- Name: webhook_trigger_events; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.webhook_trigger_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trigger_id uuid NOT NULL,
    event_name character varying(100) NOT NULL,
    template_name character varying(200) NOT NULL,
    template_language character varying(10) DEFAULT 'en'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.webhook_trigger_events OWNER TO ubuntu;

--
-- Name: webhook_triggers; Type: TABLE; Schema: public; Owner: ubuntu
--

CREATE TABLE public.webhook_triggers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    entity_id uuid NOT NULL,
    webhook_secret character varying(255) NOT NULL,
    action_type character varying(50) DEFAULT 'upsert'::character varying,
    status character varying(20) DEFAULT 'active'::character varying,
    total_calls integer DEFAULT 0,
    successful_calls integer DEFAULT 0,
    failed_calls integer DEFAULT 0,
    last_called_at timestamp without time zone,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    phone_field_path character varying(200)
);


ALTER TABLE public.webhook_triggers OWNER TO ubuntu;

--
-- Name: company_inquiries id; Type: DEFAULT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.company_inquiries ALTER COLUMN id SET DEFAULT nextval('public.company_inquiries_id_seq'::regclass);


--
-- Name: gemini_settings id; Type: DEFAULT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_settings ALTER COLUMN id SET DEFAULT nextval('public.gemini_settings_id_seq'::regclass);


--
-- Name: media_files id; Type: DEFAULT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.media_files ALTER COLUMN id SET DEFAULT nextval('public.media_files_id_seq'::regclass);


--
-- Name: template_flow_states id; Type: DEFAULT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.template_flow_states ALTER COLUMN id SET DEFAULT nextval('public.template_flow_states_id_seq'::regclass);


--
-- Name: user_flow_status id; Type: DEFAULT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.user_flow_status ALTER COLUMN id SET DEFAULT nextval('public.user_flow_status_id_seq'::regclass);


--
-- Name: bulk_messages bulk_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.bulk_messages
    ADD CONSTRAINT bulk_messages_pkey PRIMARY KEY (id);


--
-- Name: call call_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.call
    ADD CONSTRAINT call_pkey PRIMARY KEY (id);


--
-- Name: campaign_message_errors campaign_message_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_message_errors
    ADD CONSTRAINT campaign_message_errors_pkey PRIMARY KEY (id);


--
-- Name: campaign_message_status campaign_message_status_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_message_status
    ADD CONSTRAINT campaign_message_status_pkey PRIMARY KEY (id);


--
-- Name: campaign_message_status campaign_message_status_whatsapp_message_id_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_message_status
    ADD CONSTRAINT campaign_message_status_whatsapp_message_id_key UNIQUE (whatsapp_message_id);


--
-- Name: campaign_statistics campaign_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_statistics
    ADD CONSTRAINT campaign_statistics_pkey PRIMARY KEY (campaign_id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: chat_attachments chat_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.chat_attachments
    ADD CONSTRAINT chat_attachments_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_gemini_config company_gemini_config_company_id_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.company_gemini_config
    ADD CONSTRAINT company_gemini_config_company_id_key UNIQUE (company_id);


--
-- Name: company_gemini_config company_gemini_config_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.company_gemini_config
    ADD CONSTRAINT company_gemini_config_pkey PRIMARY KEY (id);


--
-- Name: company_inquiries company_inquiries_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.company_inquiries
    ADD CONSTRAINT company_inquiries_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: customers_groups customers_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.customers_groups
    ADD CONSTRAINT customers_groups_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (mobile_number);


--
-- Name: gemini_config_audit_log gemini_config_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_config_audit_log
    ADD CONSTRAINT gemini_config_audit_log_pkey PRIMARY KEY (id);


--
-- Name: gemini_file_search_stores gemini_file_search_stores_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_file_search_stores
    ADD CONSTRAINT gemini_file_search_stores_pkey PRIMARY KEY (id);


--
-- Name: gemini_file_search_stores gemini_file_search_stores_store_name_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_file_search_stores
    ADD CONSTRAINT gemini_file_search_stores_store_name_key UNIQUE (store_name);


--
-- Name: gemini_settings gemini_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_settings
    ADD CONSTRAINT gemini_settings_pkey PRIMARY KEY (id);


--
-- Name: gemini_uploads gemini_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_uploads
    ADD CONSTRAINT gemini_uploads_pkey PRIMARY KEY (id);


--
-- Name: languages languages_language_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_language_key UNIQUE (language);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: lead_interactions lead_interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.lead_interactions
    ADD CONSTRAINT lead_interactions_pkey PRIMARY KEY (id);


--
-- Name: media_files media_files_media_id_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_media_id_key UNIQUE (media_id);


--
-- Name: media_files media_files_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_pkey PRIMARY KEY (id);


--
-- Name: menuoptions menuoptions_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.menuoptions
    ADD CONSTRAINT menuoptions_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: messages messages_whatsapp_message_id_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_whatsapp_message_id_key UNIQUE (whatsapp_message_id);


--
-- Name: querytype querytype_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.querytype
    ADD CONSTRAINT querytype_pkey PRIMARY KEY (id);


--
-- Name: reportdocuments reportdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.reportdocuments
    ADD CONSTRAINT reportdocuments_pkey PRIMARY KEY (id);


--
-- Name: template_flow_states template_flow_states_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.template_flow_states
    ADD CONSTRAINT template_flow_states_pkey PRIMARY KEY (id);


--
-- Name: template_flows template_flows_name_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.template_flows
    ADD CONSTRAINT template_flows_name_key UNIQUE (name);


--
-- Name: template_flows template_flows_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.template_flows
    ADD CONSTRAINT template_flows_pkey PRIMARY KEY (id);


--
-- Name: ticketactivity ticketactivity_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.ticketactivity
    ADD CONSTRAINT ticketactivity_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tutorial_category tutorial_category_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tutorial_category
    ADD CONSTRAINT tutorial_category_pkey PRIMARY KEY (id);


--
-- Name: tutorial_category tutorial_category_title_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tutorial_category
    ADD CONSTRAINT tutorial_category_title_key UNIQUE (title);


--
-- Name: tutorial_resources tutorial_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tutorial_resources
    ADD CONSTRAINT tutorial_resources_pkey PRIMARY KEY (id);


--
-- Name: tutorials tutorials_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tutorials
    ADD CONSTRAINT tutorials_pkey PRIMARY KEY (id);


--
-- Name: tutorials tutorials_title_category_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tutorials
    ADD CONSTRAINT tutorials_title_category_key UNIQUE (title, category);


--
-- Name: user_flow_status user_flow_status_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.user_flow_status
    ADD CONSTRAINT user_flow_status_phone_number_key UNIQUE (phone_number);


--
-- Name: user_flow_status user_flow_status_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.user_flow_status
    ADD CONSTRAINT user_flow_status_pkey PRIMARY KEY (id);


--
-- Name: user_uploads user_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.user_uploads
    ADD CONSTRAINT user_uploads_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webhook_entities webhook_entities_name_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_entities
    ADD CONSTRAINT webhook_entities_name_key UNIQUE (name);


--
-- Name: webhook_entities webhook_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_entities
    ADD CONSTRAINT webhook_entities_pkey PRIMARY KEY (id);


--
-- Name: webhook_entity_fields webhook_entity_fields_entity_id_field_name_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_entity_fields
    ADD CONSTRAINT webhook_entity_fields_entity_id_field_name_key UNIQUE (entity_id, field_name);


--
-- Name: webhook_entity_fields webhook_entity_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_entity_fields
    ADD CONSTRAINT webhook_entity_fields_pkey PRIMARY KEY (id);


--
-- Name: webhook_event_params webhook_event_params_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_event_params
    ADD CONSTRAINT webhook_event_params_pkey PRIMARY KEY (id);


--
-- Name: webhook_field_mappings webhook_field_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_field_mappings
    ADD CONSTRAINT webhook_field_mappings_pkey PRIMARY KEY (id);


--
-- Name: webhook_field_mappings webhook_field_mappings_trigger_id_entity_field_id_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_field_mappings
    ADD CONSTRAINT webhook_field_mappings_trigger_id_entity_field_id_key UNIQUE (trigger_id, entity_field_id);


--
-- Name: webhook_logs webhook_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_logs
    ADD CONSTRAINT webhook_logs_pkey PRIMARY KEY (id);


--
-- Name: webhook_trigger_events webhook_trigger_events_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_trigger_events
    ADD CONSTRAINT webhook_trigger_events_pkey PRIMARY KEY (id);


--
-- Name: webhook_trigger_events webhook_trigger_events_trigger_id_event_name_key; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_trigger_events
    ADD CONSTRAINT webhook_trigger_events_trigger_id_event_name_key UNIQUE (trigger_id, event_name);


--
-- Name: webhook_triggers webhook_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_triggers
    ADD CONSTRAINT webhook_triggers_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_log_company; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_audit_log_company ON public.gemini_config_audit_log USING btree (company_id, created_at DESC);


--
-- Name: idx_bulk_messages_group; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_bulk_messages_group ON public.bulk_messages USING btree (group_id);


--
-- Name: idx_bulk_messages_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_bulk_messages_status ON public.bulk_messages USING btree (status);


--
-- Name: idx_call_cancelled_recent; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_cancelled_recent ON public.call USING btree (status, "timestamp") WHERE (status = 'cancelled'::public.conversation_status);


--
-- Name: idx_call_customer_support; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_customer_support ON public.call USING btree (customer_support);


--
-- Name: idx_call_mobile_number; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_mobile_number ON public.call USING btree (mobile_number);


--
-- Name: idx_call_query_bucket; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_query_bucket ON public.call USING btree (query_bucket);


--
-- Name: idx_call_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_status ON public.call USING btree (status);


--
-- Name: idx_call_status_support; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_status_support ON public.call USING btree (status, customer_support);


--
-- Name: idx_call_timestamp; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_timestamp ON public.call USING btree ("timestamp");


--
-- Name: idx_call_unassigned_ready; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_call_unassigned_ready ON public.call USING btree (timeslot) WHERE ((customer_support IS NULL) AND (status = 'open'::public.conversation_status));


--
-- Name: idx_campaign_errors_campaign; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_errors_campaign ON public.campaign_message_errors USING btree (campaign_id);


--
-- Name: idx_campaign_errors_code; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_errors_code ON public.campaign_message_errors USING btree (error_code);


--
-- Name: idx_campaign_errors_created_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_errors_created_at ON public.campaign_message_errors USING btree (created_at);


--
-- Name: idx_campaign_errors_mobile; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_errors_mobile ON public.campaign_message_errors USING btree (mobile_number);


--
-- Name: idx_campaign_msg_bulk_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_msg_bulk_status ON public.campaign_message_status USING btree (bulk_message_id, status);


--
-- Name: idx_campaign_msg_campaign_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_msg_campaign_status ON public.campaign_message_status USING btree (campaign_id, status);


--
-- Name: idx_campaign_msg_failed; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_msg_failed ON public.campaign_message_status USING btree (status, failed_at) WHERE ((status)::text = 'failed'::text);


--
-- Name: idx_campaign_msg_queued; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_msg_queued ON public.campaign_message_status USING btree (status, queued_at) WHERE ((status)::text = 'queued'::text);


--
-- Name: idx_campaign_msg_recipient; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_msg_recipient ON public.campaign_message_status USING btree (recipient_number, created_at DESC);


--
-- Name: idx_campaign_msg_whatsapp_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_msg_whatsapp_id ON public.campaign_message_status USING btree (whatsapp_message_id) WHERE (whatsapp_message_id IS NOT NULL);


--
-- Name: idx_campaign_stats_bulk_msg; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaign_stats_bulk_msg ON public.campaign_statistics USING btree (bulk_message_id);


--
-- Name: idx_campaigns_group_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaigns_group_id ON public.campaigns USING btree (group_id);


--
-- Name: idx_campaigns_queue_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaigns_queue_status ON public.campaigns USING btree (queue_status);


--
-- Name: idx_campaigns_scheduled_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaigns_scheduled_at ON public.campaigns USING btree (scheduled_at);


--
-- Name: idx_campaigns_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaigns_status ON public.campaigns USING btree (status);


--
-- Name: idx_campaigns_template_params; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_campaigns_template_params ON public.campaigns USING gin (template_params);


--
-- Name: idx_chat_attachments_conversation; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_chat_attachments_conversation ON public.chat_attachments USING btree (conversation_id);


--
-- Name: idx_chat_attachments_mime_type; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_chat_attachments_mime_type ON public.chat_attachments USING btree (mime_type);


--
-- Name: idx_chat_attachments_uploaded_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_chat_attachments_uploaded_at ON public.chat_attachments USING btree (uploaded_at);


--
-- Name: idx_chat_attachments_uploaded_by; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_chat_attachments_uploaded_by ON public.chat_attachments USING btree (uploaded_by);


--
-- Name: idx_company_inquiries_created_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_company_inquiries_created_at ON public.company_inquiries USING btree (created_at DESC);


--
-- Name: idx_company_inquiries_email; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_company_inquiries_email ON public.company_inquiries USING btree (email);


--
-- Name: idx_company_inquiries_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_company_inquiries_status ON public.company_inquiries USING btree (status);


--
-- Name: idx_company_inquiries_status_created_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_company_inquiries_status_created_at ON public.company_inquiries USING btree (status, created_at DESC);


--
-- Name: idx_conversations_mobile_number; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_conversations_mobile_number ON public.conversations USING btree (mobile_number);


--
-- Name: idx_conversations_rating; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_conversations_rating ON public.conversations USING btree (mobile_number, is_rated, "timestamp" DESC) WHERE (status = 'closed'::public.conversation_status);


--
-- Name: idx_conversations_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_conversations_status ON public.conversations USING btree (status);


--
-- Name: idx_conversations_timestamp; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_conversations_timestamp ON public.conversations USING btree ("timestamp");


--
-- Name: idx_customers_campaign_eligibility; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_campaign_eligibility ON public.customers USING btree (subscription_status, consent_given, opt_out_at, last_campaign_sent_at);


--
-- Name: idx_customers_consent_given; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_consent_given ON public.customers USING btree (consent_given);


--
-- Name: idx_customers_easydo_user_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_easydo_user_id ON public.customers USING btree (easydo_user_id);


--
-- Name: idx_customers_inactive_users; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_inactive_users ON public.customers USING btree (last_seen_time, consent_given, opt_out_at);


--
-- Name: idx_customers_inquiry_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_inquiry_status ON public.customers USING btree (inquiry_status);


--
-- Name: idx_customers_last_campaign_sent_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_last_campaign_sent_at ON public.customers USING btree (last_campaign_sent_at);


--
-- Name: idx_customers_last_interaction; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_last_interaction ON public.customers USING btree (last_interaction_at);


--
-- Name: idx_customers_last_seen_time; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_last_seen_time ON public.customers USING btree (last_seen_time);


--
-- Name: idx_customers_last_synced_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_last_synced_at ON public.customers USING btree (last_synced_at);


--
-- Name: idx_customers_lead_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_lead_status ON public.customers USING btree (lead_status);


--
-- Name: idx_customers_subscription_end_date; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_subscription_end_date ON public.customers USING btree (subscription_end_date);


--
-- Name: idx_customers_subscription_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_subscription_status ON public.customers USING btree (subscription_status);


--
-- Name: idx_customers_utm_source; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_customers_utm_source ON public.customers USING btree (utm_source);


--
-- Name: idx_event_params_trigger_event_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_event_params_trigger_event_id ON public.webhook_event_params USING btree (trigger_event_id);


--
-- Name: idx_gemeni_stores_api_key; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemeni_stores_api_key ON public.gemini_file_search_stores USING btree (apikey);


--
-- Name: idx_gemini_config_active; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_config_active ON public.company_gemini_config USING btree (company_id, bot_active);


--
-- Name: idx_gemini_config_company; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_config_company ON public.company_gemini_config USING btree (company_id);


--
-- Name: idx_gemini_stores_deleted_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_stores_deleted_at ON public.gemini_file_search_stores USING btree (deleted_at);


--
-- Name: idx_gemini_stores_store_name; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_stores_store_name ON public.gemini_file_search_stores USING btree (store_name);


--
-- Name: idx_gemini_stores_user_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_stores_user_id ON public.gemini_file_search_stores USING btree (user_id);


--
-- Name: idx_gemini_uploads_category; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_uploads_category ON public.gemini_uploads USING btree (file_category);


--
-- Name: idx_gemini_uploads_created_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_uploads_created_at ON public.gemini_uploads USING btree (created_at DESC);


--
-- Name: idx_gemini_uploads_deleted_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_uploads_deleted_at ON public.gemini_uploads USING btree (deleted_at);


--
-- Name: idx_gemini_uploads_name_search; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_uploads_name_search ON public.gemini_uploads USING gin (to_tsvector('english'::regconfig, (original_name)::text));


--
-- Name: idx_gemini_uploads_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_uploads_status ON public.gemini_uploads USING btree (upload_status);


--
-- Name: idx_gemini_uploads_store_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_uploads_store_id ON public.gemini_uploads USING btree (store_id);


--
-- Name: idx_gemini_uploads_user_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_gemini_uploads_user_id ON public.gemini_uploads USING btree (user_id);


--
-- Name: idx_lead_interactions_campaign; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_lead_interactions_campaign ON public.lead_interactions USING btree (campaign_id);


--
-- Name: idx_lead_interactions_created_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_lead_interactions_created_at ON public.lead_interactions USING btree (created_at);


--
-- Name: idx_lead_interactions_mobile; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_lead_interactions_mobile ON public.lead_interactions USING btree (mobile_number);


--
-- Name: idx_lead_interactions_type; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_lead_interactions_type ON public.lead_interactions USING btree (interaction_type);


--
-- Name: idx_media_files_media_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_media_files_media_id ON public.media_files USING btree (media_id);


--
-- Name: idx_media_files_phone; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_media_files_phone ON public.media_files USING btree (phone_number);


--
-- Name: idx_media_files_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_media_files_status ON public.media_files USING btree (download_status);


--
-- Name: idx_media_files_type; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_media_files_type ON public.media_files USING btree (message_type);


--
-- Name: idx_media_files_whatsapp_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_media_files_whatsapp_id ON public.media_files USING btree (whatsapp_message_id);


--
-- Name: idx_messages_channel; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_messages_channel ON public.messages USING btree (channel);


--
-- Name: idx_messages_conversation_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_messages_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: idx_messages_media_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_messages_media_id ON public.messages USING btree (media_id) WHERE (media_id IS NOT NULL);


--
-- Name: idx_messages_mime_type; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_messages_mime_type ON public.messages USING btree (media_mime_type) WHERE (media_mime_type IS NOT NULL);


--
-- Name: idx_messages_timestamp; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_messages_timestamp ON public.messages USING btree ("timestamp");


--
-- Name: idx_template_flow_states_active_user; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE UNIQUE INDEX idx_template_flow_states_active_user ON public.template_flow_states USING btree (user_phone) WHERE (is_active = true);


--
-- Name: idx_template_flow_states_flow; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_template_flow_states_flow ON public.template_flow_states USING btree (flow_id);


--
-- Name: idx_template_flow_states_message; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_template_flow_states_message ON public.template_flow_states USING btree (last_whatsapp_message_id);


--
-- Name: idx_template_flow_states_phone; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_template_flow_states_phone ON public.template_flow_states USING btree (user_phone);


--
-- Name: idx_template_flows_created_by; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_template_flows_created_by ON public.template_flows USING btree (created_by);


--
-- Name: idx_template_flows_is_active; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_template_flows_is_active ON public.template_flows USING btree (is_active);


--
-- Name: idx_template_flows_name; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_template_flows_name ON public.template_flows USING btree (name);


--
-- Name: idx_ticketactivity_ticket_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_ticketactivity_ticket_id ON public.ticketactivity USING btree (ticket_id);


--
-- Name: idx_tickets_assigned_to; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_tickets_assigned_to ON public.tickets USING btree (assigned_to);


--
-- Name: idx_tickets_created_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_tickets_created_at ON public.tickets USING btree (created_at);


--
-- Name: idx_tickets_priority; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_tickets_priority ON public.tickets USING btree (priority);


--
-- Name: idx_tickets_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_tickets_status ON public.tickets USING btree (status);


--
-- Name: idx_trigger_events_event_name; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_trigger_events_event_name ON public.webhook_trigger_events USING btree (event_name);


--
-- Name: idx_trigger_events_trigger_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_trigger_events_trigger_id ON public.webhook_trigger_events USING btree (trigger_id);


--
-- Name: idx_tutorial_category_cat_type; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_tutorial_category_cat_type ON public.tutorial_category USING btree (cat_type);


--
-- Name: idx_tutorial_resources_tag; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_tutorial_resources_tag ON public.tutorial_resources USING btree (resource_tag);


--
-- Name: idx_user_flow_status_phone; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_user_flow_status_phone ON public.user_flow_status USING btree (phone_number);


--
-- Name: idx_user_uploads_category; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_user_uploads_category ON public.user_uploads USING btree (file_category);


--
-- Name: idx_user_uploads_created_at; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_user_uploads_created_at ON public.user_uploads USING btree (created_at DESC);


--
-- Name: idx_user_uploads_drive_file_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_user_uploads_drive_file_id ON public.user_uploads USING btree (drive_file_id);


--
-- Name: idx_user_uploads_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_user_uploads_status ON public.user_uploads USING btree (upload_status);


--
-- Name: idx_user_uploads_tags; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_user_uploads_tags ON public.user_uploads USING gin (tags);


--
-- Name: idx_user_uploads_user_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_user_uploads_user_id ON public.user_uploads USING btree (user_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_users_company; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_users_company ON public.users USING btree (company_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_webhook_entities_active; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_entities_active ON public.webhook_entities USING btree (is_active);


--
-- Name: idx_webhook_entities_name; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_entities_name ON public.webhook_entities USING btree (name);


--
-- Name: idx_webhook_entity_fields_entity; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_entity_fields_entity ON public.webhook_entity_fields USING btree (entity_id);


--
-- Name: idx_webhook_entity_fields_identifier; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_entity_fields_identifier ON public.webhook_entity_fields USING btree (entity_id, is_identifier);


--
-- Name: idx_webhook_field_mappings_trigger; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_field_mappings_trigger ON public.webhook_field_mappings USING btree (trigger_id);


--
-- Name: idx_webhook_logs_trigger; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_logs_trigger ON public.webhook_logs USING btree (trigger_id);


--
-- Name: idx_webhook_triggers_created_by; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_triggers_created_by ON public.webhook_triggers USING btree (created_by);


--
-- Name: idx_webhook_triggers_entity; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_triggers_entity ON public.webhook_triggers USING btree (entity_id);


--
-- Name: idx_webhook_triggers_status; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX idx_webhook_triggers_status ON public.webhook_triggers USING btree (status);


--
-- Name: indx_message_reply_id; Type: INDEX; Schema: public; Owner: ubuntu
--

CREATE INDEX indx_message_reply_id ON public.messages USING btree (message_reply_id);


--
-- Name: campaigns campaign_status_change_trigger; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER campaign_status_change_trigger AFTER UPDATE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.notify_campaign_status_change();


--
-- Name: TRIGGER campaign_status_change_trigger ON campaigns; Type: COMMENT; Schema: public; Owner: ubuntu
--

COMMENT ON TRIGGER campaign_status_change_trigger ON public.campaigns IS 'Triggers notification when campaign status is updated';


--
-- Name: campaigns campaigns_updated_at_trigger; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER campaigns_updated_at_trigger BEFORE UPDATE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.update_campaigns_updated_at();


--
-- Name: conversations trigger_add_customer; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_add_customer AFTER INSERT ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.add_customer_on_conversation();


--
-- Name: tickets trigger_set_assigned_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_set_assigned_at BEFORE INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.set_assigned_at();


--
-- Name: campaign_message_status trigger_update_campaign_message_status_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_campaign_message_status_updated_at BEFORE UPDATE ON public.campaign_message_status FOR EACH ROW EXECUTE FUNCTION public.update_campaign_message_status_updated_at();


--
-- Name: campaign_message_status trigger_update_campaign_statistics; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_campaign_statistics AFTER INSERT OR UPDATE ON public.campaign_message_status FOR EACH ROW EXECUTE FUNCTION public.update_campaign_statistics();


--
-- Name: lead_interactions trigger_update_customer_interaction; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_customer_interaction AFTER INSERT ON public.lead_interactions FOR EACH ROW WHEN (((new.interaction_type)::text = ANY ((ARRAY['message_received'::character varying, 'button_clicked'::character varying, 'opt_in'::character varying])::text[]))) EXECUTE FUNCTION public.update_customer_last_interaction();


--
-- Name: gemini_settings trigger_update_gemini_settings; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_gemini_settings BEFORE UPDATE ON public.gemini_settings FOR EACH ROW EXECUTE FUNCTION public.update_gemini_settings_timestamp();


--
-- Name: template_flow_states trigger_update_template_flow_states_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_template_flow_states_updated_at BEFORE UPDATE ON public.template_flow_states FOR EACH ROW EXECUTE FUNCTION public.update_template_flow_states_updated_at();


--
-- Name: template_flows trigger_update_template_flows_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_template_flows_updated_at BEFORE UPDATE ON public.template_flows FOR EACH ROW EXECUTE FUNCTION public.update_template_flows_updated_at();


--
-- Name: user_flow_status trigger_update_user_flow_status_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_user_flow_status_updated_at BEFORE UPDATE ON public.user_flow_status FOR EACH ROW EXECUTE FUNCTION public.update_user_flow_status_updated_at();


--
-- Name: user_uploads trigger_update_user_uploads_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER trigger_update_user_uploads_updated_at BEFORE UPDATE ON public.user_uploads FOR EACH ROW EXECUTE FUNCTION public.update_user_uploads_updated_at();


--
-- Name: chat_attachments update_chat_attachments_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_chat_attachments_updated_at BEFORE UPDATE ON public.chat_attachments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: customers update_customers_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: gemini_file_search_stores update_gemini_stores_timestamp; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_gemini_stores_timestamp BEFORE UPDATE ON public.gemini_file_search_stores FOR EACH ROW EXECUTE FUNCTION public.update_gemini_timestamp();


--
-- Name: gemini_uploads update_gemini_uploads_timestamp; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_gemini_uploads_timestamp BEFORE UPDATE ON public.gemini_uploads FOR EACH ROW EXECUTE FUNCTION public.update_gemini_timestamp();


--
-- Name: media_files update_media_files_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_media_files_updated_at BEFORE UPDATE ON public.media_files FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: messages update_messages_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: tickets update_tickets_last_updated; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_tickets_last_updated BEFORE UPDATE ON public.tickets FOR EACH ROW WHEN ((((old.title)::text IS DISTINCT FROM (new.title)::text) OR ((old.description)::text IS DISTINCT FROM (new.description)::text) OR (old.next_follow_up IS DISTINCT FROM new.next_follow_up) OR (old.assigned_to IS DISTINCT FROM new.assigned_to) OR (old.activities IS DISTINCT FROM new.activities) OR (old.status IS DISTINCT FROM new.status) OR (old.priority IS DISTINCT FROM new.priority))) EXECUTE FUNCTION public.update_last_updated_at();


--
-- Name: webhook_entities update_webhook_entities_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_webhook_entities_updated_at BEFORE UPDATE ON public.webhook_entities FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: webhook_triggers update_webhook_triggers_updated_at; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER update_webhook_triggers_updated_at BEFORE UPDATE ON public.webhook_triggers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users user_status_change_trigger; Type: TRIGGER; Schema: public; Owner: ubuntu
--

CREATE TRIGGER user_status_change_trigger AFTER UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.notify_user_status_change();


--
-- Name: bulk_messages bulk_messages_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.bulk_messages
    ADD CONSTRAINT bulk_messages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: bulk_messages bulk_messages_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.bulk_messages
    ADD CONSTRAINT bulk_messages_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.customers_groups(id) ON DELETE CASCADE;


--
-- Name: campaign_message_errors campaign_message_errors_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_message_errors
    ADD CONSTRAINT campaign_message_errors_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: campaign_message_status campaign_message_status_bulk_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_message_status
    ADD CONSTRAINT campaign_message_status_bulk_message_id_fkey FOREIGN KEY (bulk_message_id) REFERENCES public.bulk_messages(id) ON DELETE CASCADE;


--
-- Name: campaign_message_status campaign_message_status_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_message_status
    ADD CONSTRAINT campaign_message_status_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: campaign_statistics campaign_statistics_bulk_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_statistics
    ADD CONSTRAINT campaign_statistics_bulk_message_id_fkey FOREIGN KEY (bulk_message_id) REFERENCES public.bulk_messages(id) ON DELETE CASCADE;


--
-- Name: campaign_statistics campaign_statistics_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaign_statistics
    ADD CONSTRAINT campaign_statistics_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: campaigns campaigns_bulk_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_bulk_message_id_fkey FOREIGN KEY (bulk_message_id) REFERENCES public.bulk_messages(id);


--
-- Name: campaigns campaigns_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: campaigns campaigns_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.customers_groups(id) ON DELETE CASCADE;


--
-- Name: chat_attachments chat_attachments_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.chat_attachments
    ADD CONSTRAINT chat_attachments_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: chat_attachments chat_attachments_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.chat_attachments
    ADD CONSTRAINT chat_attachments_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: company_gemini_config company_gemini_config_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.company_gemini_config
    ADD CONSTRAINT company_gemini_config_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: company_gemini_config company_gemini_config_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.company_gemini_config
    ADD CONSTRAINT company_gemini_config_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: company_gemini_config company_gemini_config_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.company_gemini_config
    ADD CONSTRAINT company_gemini_config_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: customers customers_gid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_gid_fkey FOREIGN KEY (gid) REFERENCES public.customers_groups(id);


--
-- Name: call fk_call_users; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.call
    ADD CONSTRAINT fk_call_users FOREIGN KEY (customer_support) REFERENCES public.users(id);


--
-- Name: conversations fk_conversations_tickets; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_conversations_tickets FOREIGN KEY (ticket_id) REFERENCES public.tickets(id);


--
-- Name: conversations fk_conversations_users; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_conversations_users FOREIGN KEY (customer_support) REFERENCES public.users(id);


--
-- Name: messages fk_message_reply_id; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_message_reply_id FOREIGN KEY (message_reply_id) REFERENCES public.messages(id);


--
-- Name: messages fk_messages_conversations; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_messages_conversations FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: gemini_config_audit_log gemini_config_audit_log_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_config_audit_log
    ADD CONSTRAINT gemini_config_audit_log_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: gemini_config_audit_log gemini_config_audit_log_performed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_config_audit_log
    ADD CONSTRAINT gemini_config_audit_log_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.users(id);


--
-- Name: gemini_file_search_stores gemini_file_search_stores_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_file_search_stores
    ADD CONSTRAINT gemini_file_search_stores_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: gemini_settings gemini_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_settings
    ADD CONSTRAINT gemini_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: gemini_uploads gemini_uploads_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_uploads
    ADD CONSTRAINT gemini_uploads_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.gemini_file_search_stores(id) ON DELETE CASCADE;


--
-- Name: gemini_uploads gemini_uploads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.gemini_uploads
    ADD CONSTRAINT gemini_uploads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: lead_interactions lead_interactions_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.lead_interactions
    ADD CONSTRAINT lead_interactions_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: template_flow_states template_flow_states_flow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.template_flow_states
    ADD CONSTRAINT template_flow_states_flow_id_fkey FOREIGN KEY (flow_id) REFERENCES public.template_flows(id) ON DELETE CASCADE;


--
-- Name: template_flows template_flows_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.template_flows
    ADD CONSTRAINT template_flows_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: template_flows template_flows_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.template_flows
    ADD CONSTRAINT template_flows_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: tutorial_resources tutorial_resources_tutorial_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tutorial_resources
    ADD CONSTRAINT tutorial_resources_tutorial_id_fkey FOREIGN KEY (tutorial_id) REFERENCES public.tutorials(id) ON DELETE CASCADE;


--
-- Name: tutorials tutorials_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.tutorials
    ADD CONSTRAINT tutorials_category_fkey FOREIGN KEY (category) REFERENCES public.tutorial_category(id) ON DELETE CASCADE;


--
-- Name: user_uploads user_uploads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.user_uploads
    ADD CONSTRAINT user_uploads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: webhook_entity_fields webhook_entity_fields_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_entity_fields
    ADD CONSTRAINT webhook_entity_fields_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.webhook_entities(id) ON DELETE CASCADE;


--
-- Name: webhook_event_params webhook_event_params_trigger_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_event_params
    ADD CONSTRAINT webhook_event_params_trigger_event_id_fkey FOREIGN KEY (trigger_event_id) REFERENCES public.webhook_trigger_events(id) ON DELETE CASCADE;


--
-- Name: webhook_field_mappings webhook_field_mappings_entity_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_field_mappings
    ADD CONSTRAINT webhook_field_mappings_entity_field_id_fkey FOREIGN KEY (entity_field_id) REFERENCES public.webhook_entity_fields(id);


--
-- Name: webhook_field_mappings webhook_field_mappings_trigger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_field_mappings
    ADD CONSTRAINT webhook_field_mappings_trigger_id_fkey FOREIGN KEY (trigger_id) REFERENCES public.webhook_triggers(id) ON DELETE CASCADE;


--
-- Name: webhook_logs webhook_logs_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_logs
    ADD CONSTRAINT webhook_logs_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.webhook_entities(id);


--
-- Name: webhook_logs webhook_logs_trigger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_logs
    ADD CONSTRAINT webhook_logs_trigger_id_fkey FOREIGN KEY (trigger_id) REFERENCES public.webhook_triggers(id);


--
-- Name: webhook_trigger_events webhook_trigger_events_trigger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_trigger_events
    ADD CONSTRAINT webhook_trigger_events_trigger_id_fkey FOREIGN KEY (trigger_id) REFERENCES public.webhook_triggers(id) ON DELETE CASCADE;


--
-- Name: webhook_triggers webhook_triggers_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_triggers
    ADD CONSTRAINT webhook_triggers_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: webhook_triggers webhook_triggers_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ubuntu
--

ALTER TABLE ONLY public.webhook_triggers
    ADD CONSTRAINT webhook_triggers_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.webhook_entities(id);


--
-- PostgreSQL database dump complete
--

\unrestrict bcVgIw5UElfqNtgPVrCb5us8GzecPxEInO8d7RgfFdNh7SocIK3MhlanABoUNg2

