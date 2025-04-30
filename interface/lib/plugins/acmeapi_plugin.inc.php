<?php
/*
 * Copyright (c) 2025.
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice,
 *       this list of conditions and the following disclaimer in the documentation
 *       and/or other materials provided with the distribution.
 *     * Neither the name of ISPConfig nor the names of its contributors
 *       may be used to endorse or promote products derived from this software without
 *       specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @file        acmeapi_plugin.inc.php
 * @author      Johannes Koschier <hannes@cheat.at>
 *
 */

class acmeapi_plugin
{
    public string $plugin_name = 'acmeapi_plugin';
    public string $class_name = 'acmeapi_plugin';

    public string $plugin_dir;

    public function __construct()
    {
        $this->plugin_dir = ISPC_ROOT_PATH . '/lib/plugins/' . $this->plugin_name;
    }


    public function onLoad(): void
    {
        global $app,$conf;

        $app->plugin->registerEvent('admin:server_config:on_after_formdef', $this->plugin_name, 'server_config_form');

        if ($this->checkDbColumnExist()) {
            $app->plugin->registerEvent('dns:dns_soa:on_after_formdef', $this->plugin_name, 'dns_soa_form');
            $app->plugin->registerEvent('dns:dns_soa:on_before_update', $this->plugin_name, 'dns_soa_form_on_before_update');
        } elseif ($_SESSION["s"]["user"]["typ"] == 'admin') {
            $app->plugin->registerEvent('dns:dns_soa:on_after_formdef', $this->plugin_name, 'dns_soa_form_notready');
        }
    }

    public function server_config_form($event_name, $page_form): void
    {
        $this->loadLang($page_form);

        $tabs = array(
            'plugin_acmeapi' => array(
                'title' => 'AMCEAPI (Plugin)',
                'width' => 100,
                'template' => $this->plugin_dir . '/templates/plugin_acmeapi_server_config_edit.htm',
                'fields' => array(
                    'plugin_acmeapi_enabled' => array(
                        'datatype' => 'VARCHAR',
                        'formtype' => 'CHECKBOX',
                        'default' => 'n',
                        'value' => array(
                            1 => 'y',
                            0 => 'n'
                        )
                    ),
                    'plugin_acmeapi_url' => array(
                        'datatype' => 'VARCHAR',
                        'formtype' => 'TEXT',
                        'filters' => array(
                            0 => array(
                                'event' => 'SAVE',
                                'type' => 'TRIM'
                            )
                        ),
                        'default' => '',
                        'value' => '',
                        'maxlength' => '255'
                    ),
                    'plugin_acmeapi_help_url' => array(
                        'datatype' => 'VARCHAR',
                        'formtype' => 'TEXT',
                        'filters' => array(
                            0 => array(
                                'event' => 'SAVE',
                                'type' => 'TRIM'
                            )
                        ),
                        'default' => '',
                        'value' => '',
                        'maxlength' => '255'
                    ),
                    'plugin_acmeapi_help_url_text' => array(
                        'datatype' => 'VARCHAR',
                        'formtype' => 'TEXT',
                        'filters' => array(
                            0 => array(
                                'event' => 'SAVE',
                                'type' => 'TRIM'
                            )
                        ),
                        'default' => '',
                        'value' => '',
                        'maxlength' => '255'
                    ),
                )
            )
        );

        $this->insert($tabs, $page_form);
    }
    public function dns_soa_form($event_name, $page_form): void
    {
        global $app,$conf;

        //Workaround - get zone id
        $zone_id = $app->functions->intval(@$_REQUEST['id']);

        //Get Server ID from $zone_id
        $tmp = $app->db->queryOneRecord("SELECT server_id FROM dns_soa WHERE id = ?", $zone_id);
        $server_id = $tmp["server_id"];

        $settings = $app->getconf->get_server_config($server_id,'plugin_acmeapi');
        if ($settings['plugin_acmeapi_enabled'] != 'y') {
            return;
        }

        //Workaround to get info into tpl - no access to tpl from plugin
        $addWB['plugin_acmeapi_url'] = $settings['plugin_acmeapi_url'];
        $addWB['plugin_acmeapi_help_url'] = $settings['plugin_acmeapi_help_url'];
        $addWB['plugin_acmeapi_help_url_text'] = $settings['plugin_acmeapi_help_url_text'];

        $this->loadLang($page_form,$addWB);

        $tabs = array (
            'plugin_acmeapi' => array(
            'title'  => "AMCEAPI (Plugin)",
            'width'  => 100,
            'template'  => $this->plugin_dir . '/templates/plugin_acmeapi_soa_edit_tab.htm',
            'fields'  => array (
                'plugin_acmeapi_key' => array (
                    'datatype' => 'VARCHAR',
                    'formtype' => 'TEXT',
                ),
            )
        ));

        $this->insert($tabs, $page_form);
    }

    public function dns_soa_form_notready($event_name, $page_form): void
    {
        $this->loadLang($page_form);

        $tabs = array (
            'plugin_acmeapi' => array(
                'title'  => "AMCEAPI (Plugin)",
                'width'  => 100,
                'template'  => $this->plugin_dir . '/templates/plugin_acmeapi_soa_edit_tab_notready.htm',
            ));

        $this->insert($tabs, $page_form);
    }

    public function dns_soa_form_on_before_update($event_name, $page_form): void {
        global $app;

        if (! isset($_GET['acmetask'])) { // ignore all other tabs
            return;
        }

        $domain_id = $page_form->dataRecord['id'];
        if (!is_numeric($domain_id)) {
            die("Domain ID not numeric"); //should never happen...
        }

        if ($_SESSION["s"]["user"]["typ"] != 'admin') {
            $clientGroupId = $_SESSION["s"]["user"]["default_group"];
            $sql = "SELECT `id` FROM dns_soa WHERE `id` = ? AND sys_groupid = ?";
            $res = $app->db->queryOneRecord($sql, $domain_id, $clientGroupId);
            if (!is_array($res)) {
                die("Domain with ID " . $domain_id . " not found or no permission"); //should never happen...
            }
        }
        if ($_GET['acmetask'] == 'create') {
            $newApiKey = bin2hex(random_bytes(16)); //32 chars long
        } elseif ($_GET['acmetask'] == 'delete') {
            $newApiKey = NULL;
        } else {
            die("No valid task given - exiting");
        }

        $sql = "UPDATE `dns_soa` SET `plugin_acmeapi_key` = ? WHERE `dns_soa`.`id` = ?";
        $app->db->query($sql, $newApiKey, $domain_id); //Insert into dns_soa table
        header("Location: /dns/dns_soa_edit.php?next_tab=plugin_acmeapi&id=$domain_id");
        exit;
    }

    private function checkDbColumnExist()
    {
        global $app;

        $sql = "SHOW COLUMNS FROM `dns_soa` WHERE FIELD IN('plugin_acmeapi_key')";
        $result = $app->db->queryAllArray($sql);
        if (! $result) {
            return false;
        }
        return true;
    }

    private function loadLang($page_form,$addwb=null): void
    {
        global $app, $conf;

        $language = $app->functions->check_language(
            $_SESSION['s']['user']['language'] ?? $conf['language']
        );
        $file = $this->plugin_dir . "/lib/lang/$language.lng";

        if (!is_file($file)) {
            $file = $this->plugin_dir . "/lib/lang/en.lng";
        }

        @include $file;
        if (is_array($addwb)) {
            $wb = array_merge($wb, $addwb); // work around to get url texts into template
        }
        if (isset($page_form->wordbook) && isset($wb) && is_array($wb)) {

            if (is_array($page_form->wordbook)) {
                $page_form->wordbook = array_merge($page_form->wordbook, $wb);
            } else {
                $page_form->wordbook = $wb;
            }
        }
    }

    private function insert($tabs, $page_form): void
    {
        if (isset($page_form->formDef['tabs'])) {
            $page_form->formDef['tabs'] += $tabs;
        } elseif (isset($page_form->formDef['fields'])) {
            foreach ($tabs as $tab) {
                foreach ($tab['fields'] as $key => $value) {
                    $page_form->formDef['fields'][$key] = $value;
                }
            }
        }
    }
}
