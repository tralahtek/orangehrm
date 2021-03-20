<?php
/**
 * OrangeHRM is a comprehensive Human Resource Management (HRM) System that captures
 * all the essential functionalities required for any enterprise.
 * Copyright (C) 2006 OrangeHRM Inc., http://www.orangehrm.com
 *
 * OrangeHRM is free software; you can redistribute it and/or modify it under the terms of
 * the GNU General Public License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * OrangeHRM is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program;
 * if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301, USA
 */

use Orangehrm\Rest\Api\Exception\BadRequestException;
use Orangehrm\Rest\Api\Exception\InvalidParamException;
use Orangehrm\Rest\Api\Exception\NotImplementedException;
use Orangehrm\Rest\Api\Exception\RecordNotFoundException;
use Orangehrm\Rest\Api\Validator;
use Orangehrm\Rest\Http\Request;
use Orangehrm\Rest\Http\Response;
use Orangehrm\Rest\Service\ApiUsageService;
use OpenApi\Annotations as OA;

/**
 * @OA\OpenApi(openapi="3.0.3")
 * @OA\Info(
 *     title="OrangeHRM Open Source : REST api docs",
 *     version="1.3.0",
 *     x={
 *         "base-path": "/api/v1"
 *     }
 * )
 * @OA\Server(
 *     url="{schema}://{your-orangehrm-host}/{basePath}",
 *     variables={@OA\ServerVariable(serverVariable="schema",default="https",enum={"https","http"}),
 *     @OA\ServerVariable(serverVariable="your-orangehrm-host",default="your-orangehrm-host"),
 *     @OA\ServerVariable(serverVariable="basePath",default="api/v1")}
 * )
 * @OA\Server(
 *     url="{schema}://{your-orangehrm-host}",
 *     variables={@OA\ServerVariable(serverVariable="schema",default="https",enum={"https","http"}),
 *     @OA\ServerVariable(serverVariable="your-orangehrm-host",default="your-orangehrm-host")}
 * )
 *
 * @OA\SecurityScheme(
 *     securityScheme="OAuth",
 *     type="oauth2",
 *     flows={@OA\Flow(flow="password",tokenUrl="./oauth/issueToken",scopes={"admin":"Privileged APIs","user":"User scope APIs"})}
 * )
 *
 * @OA\Tag(name="Leave")
 * @OA\Tag(name="Attendance")
 * @OA\Tag(name="Time")
 * @OA\Schema(
 *     schema="RecordNotFoundException",
 *     type="object",
 *     example={"error":{"status":"404","text":"No Records Found"}}
 * )
 */
abstract class baseRestAction extends baseOAuthAction {

    protected $getValidationRule = array();
    protected $postValidationRule = array();
    protected $putValidationRule = array();
    protected $deleteValidationRule = array();
    protected $apiUsageService = null;

    /**
     * Check token validation
     */
    public function preExecute() {
        parent::preExecute();
        $this->verifyAllowedScope();
        $this->getApiUsageService()->persistApiRequestMetaData($this->getAccessTokenData(), $this->getRequest());
    }

    protected function init(Request $request){

    }

    /**
     * @param Request $request
     * @return Response
     */
    abstract protected function handleGetRequest(Request $request);

    /**
     * @param Request $request
     * @return Response
     */
    abstract protected function handlePostRequest(Request $request);

    /**
     * @param Request $request
     * @throws NotImplementedException
     */
    protected function handlePutRequest(Request $request){
        throw new NotImplementedException('method not implemented');
    }

    /**
     * @param Request $request
     * @throws NotImplementedException
     */
    protected function handleDeleteRequest(Request $request){
        throw new NotImplementedException('method not implemented');
    }

    /**
     * @return array
     */
    protected function getValidationRule($request) {
        switch($request->getMethod()){
            case 'GET';
                return $this->getValidationRule;
                break;
            case 'POST':
                return $this->postValidationRule;
                break;
            case 'PUT':
                return $this->putValidationRule;
                break;
            case 'DELETE':
                return $this->deleteValidationRule;
                break;
        }
    }

    /**
     * @param sfWebRequest $request
     * @return string
     */
    public function execute($request) {
        $httpRequest = new Request($request);
        $this->init($httpRequest);
        $response = $this->getResponse();
        $response->setHttpHeader('Content-type', 'application/json');
        try{

            if(!empty($this->getValidationRule($request))) {
                Validator::validate($httpRequest->getAllParameters(),$this->getValidationRule($request));
            }
            switch($request->getMethod()){
                case 'GET';
                    $response->setContent($this->handleGetRequest($httpRequest)->formatData());
                    break;

                case 'POST':
                    $response->setContent($this->handlePostRequest($httpRequest)->format());
                    break;
                case 'PUT':
                    $response->setContent($this->handlePutRequest($httpRequest)->format());
                    break;
                case 'DELETE':
                    $response->setContent($this->handleDeleteRequest($httpRequest)->format());
                    break;
                default:
                    throw new NotImplementedException();
            }

        } catch (RecordNotFoundException $e){
            $response->setContent(Response::formatError(
                array('error'=>array('status'=>'404','text'=>$e->getMessage())))
            );
            $response->setStatusCode(404);
        } catch (InvalidParamException $e){
            $response->setContent(Response::formatError(
                array('error'=>array('status'=>'202','text'=>$e->getMessage())))
            );
            $response->setStatusCode(202);
        } catch (NotImplementedException $e){
            $response->setContent(Response::formatError(
                array('error'=>array('status'=>'501','text'=>'Not Implemented')))
            );
            $response->setStatusCode(501);
        } catch(BadRequestException $e) {
            $response->setContent(Response::formatError(
                array('error'=>array($e->getMessage())))
            );
            $response->setStatusCode(400);
        } catch(Exception $e) {
            $response->setContent(Response::formatError(
                array('error'=>array($e->getMessage())))
            );
            $response->setStatusCode(500);
        }


        return sfView::NONE;
    }

    /**
     * Check allowed scopes. By default check `privileged` for non-mobile endpoints
     * @throws sfStopException
     */
    public function verifyAllowedScope()
    {
        $oauthRequest = $this->getOAuthRequest();
        $oauthResponse = $this->getOAuthResponse();
        if (!$this->getOAuthServer()->verifyResourceRequest(
            $oauthRequest,
            $oauthResponse,
            Scope::SCOPE_ADMIN
        )) {
            $oauthResponse->send();
            throw new sfStopException();
        }
    }

    public function getApiUsageService()
    {
        if (is_null($this->apiUsageService)) {
            $this->apiUsageService = new ApiUsageService();
        }
        return $this->apiUsageService;
    }
}

